%w[ lib ].each do |path|
  $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)
end

require "sinatra"
require "json"
require "csv"

require "document"
require "result_set_presenter"
require "govuk_searcher"
require "govuk_search_presenter"
require "unified_searcher"
require "organisation_set_presenter"
require "registry"
require "suggester"
require "elasticsearch/index"
require "elasticsearch/search_server"
require "redis"
require "matcher_set"
require "search_parameter_parser"

require_relative "config"
require_relative "helpers"

class Rummager < Sinatra::Application
  def search_server
    settings.search_config.search_server
  end

  def current_index
    index_name = params["index"] || settings.default_index_name
    search_server.index(index_name)
  rescue Elasticsearch::NoSuchIndex
    halt(404)
  end

  def document_series_registry
    index_name = settings.search_config.document_series_registry_index
    @@document_series_registry ||= Registry::DocumentSeries.new(search_server.index(index_name)) if index_name
  end

  def document_collection_registry
    index_name = settings.search_config.document_collection_registry_index
    @@document_collection_registry ||= Registry::DocumentCollection.new(search_server.index(index_name)) if index_name
  end

  def organisation_registry
    index_name = settings.search_config.organisation_registry_index
    @@organisation_registry ||= Registry::Organisation.new(search_server.index(index_name)) if index_name
  end

  def topic_registry
    index_name = settings.search_config.topic_registry_index
    @@topic_registry ||= Registry::Topic.new(search_server.index(index_name)) if index_name
  end

  def world_location_registry
    index_name = settings.search_config.world_location_registry_index
    @@world_location_registry ||= Registry::WorldLocation.new(search_server.index(index_name)) if index_name
  end

  def specialist_sector_registry
    @@specialist_sector_registry ||= Registry::SpecialistSector.new(unified_index)
  end

  def govuk_indices
    settings.search_config.govuk_index_names.map do |index_name|
      search_server.index(index_name)
    end
  end

  def unified_index
    search_server.index_for_search(settings.search_config.govuk_index_names)
  end

  def metasearch_index
    search_server.index(settings.search_config.metasearch_index_name)
  end

  def lines_from_a_file(filepath)
    path = File.expand_path(filepath, File.dirname(__FILE__))
    lines = File.open(path).map(&:chomp)
    lines.reject { |line| line.start_with?('#') || line.empty? }
  end

  def ignores_from_file
    @@_ignores_from_file ||= lines_from_a_file("config/suggest/ignore.txt")
  end

  def blacklist_from_file
    @@_blacklist_from_file ||= lines_from_a_file("config/suggest/blacklist.txt")
  end

  def suggester
    ignore = ignores_from_file
    if organisation_registry
      ignore = ignore + organisation_registry.all.map(&:acronym).reject(&:nil?)
    end
    digit_or_word_containing_a_digit = /\d/
    ignore = ignore + [digit_or_word_containing_a_digit]
    Suggester.new(ignore: MatcherSet.new(ignore),
                  blacklist: MatcherSet.new(blacklist_from_file))
  end

  def text_error(content)
    halt 403, {"Content-Type" => "text/plain"}, content
  end

  def json_only
    unless [nil, "json"].include? params[:request_format]
      expires 86400, :public
      halt 404
    end
  end

  helpers do
    include Helpers
  end

  before do
    content_type :json
  end

  error RestClient::RequestTimeout do
    halt(503, "Elasticsearch timed out")
  end

  error Redis::TimeoutError do
    halt(503, "Redis queue timed out")
  end

  error Elasticsearch::InvalidQuery do
    halt(422, env['sinatra.error'].message)
  end

  error Elasticsearch::BulkIndexFailure do
    halt(500, env['sinatra.error'].message)
  end

  before "/?:index?/search.?:request_format?" do
    @query = params["q"].to_s.gsub(/[\u{0}-\u{1f}]/, "").strip

    if @query == ""
      expires 3600, :public
      halt 404
    end

    expires 3600, :public if @query.length < 20
  end

  # A mix of search results tailored for the GOV.UK site search
  #
  # The response looks like this:
  #
  #   {
  #     "streams": {
  #       "top-results": {
  #         "title": "Top results",
  #         "total": 3,
  #         "results": [
  #           ...
  #         ]
  #       },
  #       "services-information": {
  #         "title": "Services and information",
  #         "total": 25,
  #         "results": [
  #           ...
  #         ]
  #       },
  #       "departments-policy": {
  #         "title": "Departments and policy",
  #         "total": 19,
  #         "results": [
  #           ...
  #         ]
  #       }
  #     },
  #     "spelling_suggestions": [
  #       ...
  #     ]
  #   }
  get "/govuk/search.?:request_format?" do
    json_only

    organisation = params["organisation_slug"] == "" ? nil : params["organisation_slug"]

    searcher = GovukSearcher.new(*govuk_indices)
    result_streams = searcher.search(@query, organisation, params["sort"])

    result_context = {
      organisation_registry: organisation_registry,
      topic_registry: topic_registry,
      document_series_registry: document_series_registry,
      document_collection_registry: document_collection_registry,
      world_location_registry: world_location_registry
    }

    output = GovukSearchPresenter.new(result_streams, result_context).present
    output["spelling_suggestions"] = suggester.suggestions(@query)

    output.to_json
  end

  # Return a unified set of results for the GOV.UK site search.
  #
  # Parameters:
  #   q: User-entered search query
  #
  #   start: Position in search result list to start returning results
  #   (0-based)
  #
  #   count: Maximum number of search results to return.
  #
  #   order: The sort order.  A fieldname, with an optional preceding
  #   "-" to sort in descending order.  If not specified, sort order is
  #   relevance.
  #
  #   filter_FIELD[]: (where FIELD is a fieldname); a filter to apply to a
  #   field.  Multiple values may be given for a single field.  The filters are
  #   grouped by fieldname; documents will only be returned if they match all
  #   of the filter groups, and they will be considered to match a filter group
  #   if any of the individual filters in that group match.
  #
  #   facet_FIELD: (where FIELD is a fieldname); count up values which are
  #   present in the field in the documents matched by the search, and return
  #   information about these.  The value of this parameter is a comma
  #   separated list of options; the first option in the list is an integer
  #   which controls the requested number of distinct field values to be
  #   returned for the field.  Subsequent options are optional, and are colon
  #   separated key:value pairs:
  #
  #   - order:<colon separated list of ordering types>
  #
  #     The available ordering types are:
  #
  #     - count: order by the number of documents in the search matching the
  #       facet value.
  #     - slug: the slug in the facet value
  #     - link: the link in the facet value
  #     - title: the title in the facet value
  #     - filtered: whether the value is used in an active filter
  #     
  #     Each ordering may be preceded by a "-" to sort in descending order.
  #     Multiple orderings can be specified, in priority order, separated by a
  #     colon.  The default ordering is "filtered:-count:slug".
  #
  #   - examples:<integer number of example values to return>  This causes
  #     facet values to contain an "examples" hash as an additional field,
  #     which contains details of example documents which match the query.  The
  #     examples are sorted by decreasing popularity.  An example facet value
  #     in a response with this option set as "examples:1" might look like:
  #
  #         "value" => {
  #           "slug" => "an-example-facet-slug",
  #           "example_info" => {
  #             "total" => 3,  # The total number of matching examples
  #             "examples" => [
  #               {"title" => "Title of the first example", "link" => "/foo"},
  #             ],
  #           }
  #         }
  #
  #   - example_scope:global.  If the examples option is supplied, the
  #     example_scope:global option must be supplied too; this causes the
  #     returned examples to be taken from all documents in which the facet
  #     field has the given slug, rather than only from such documents which
  #     match the query.
  #
  #   - example_fields:<colon separated list of fields>.  If the examples
  #     option is supplied, this lists the fields which are returned for
  #     each example.  By default, only a small number of fields are returned
  #     for each.  Note that the list is colon separated rather than comma
  #     separated, since commas are used to separate different options.
  #
  #   Regardless of the parameter value, a facet value will be returned for any
  #   filter which is in place on the field. This may cause the requested
  #   number of values to be exceeded.
  #
  #   fields[]: fields to be returned in the result documents.  By default, all
  #   allowed fields will be returned, but this can be used to restrict the
  #   size of the response documents when only some fields are wanted.
  #
  #   When combining facet calculation and filters, the API tries to do the
  #   "right" thing for most user interfaces.  This means that when calculating
  #   facet values for field A, if there are filters for field A and B, the
  #   facet values are calculated as if the filters for field B are applied,
  #   but not those for field A.
  #
  #
  # For example:
  #
  #     /unified_search.json?
  #      q=foo&
  #      start=0&
  #      count=20&
  #      order=-public_timestamp&
  #      filter_organisations[]=cabinet-office&
  #      filter_organisations[]=driver-vehicle-licensing-agency&
  #      filter_section[]=driving
  #      facet_organisations=10
  #
  # Returns something like:
  #
  #     {
  #       "results": [
  #         {...},
  #         {...}
  #       ],
  #       "total": 19,
  #       "offset": 0,
  #       "spelling_suggestions": [
  #         ...
  #       ],
  #       "facets": {
  #         "organisations": {
  #           "options": [
  #             {
  #               "value": "department-for-business-innovation-skills",
  #               "documents": 788
  #             }, ...],
  #           "documents_with_no_value": 1610,
  #           "total_options": 94,
  #           "missing_options": 84
  #         }
  #       }
  #     }
  #
  get "/unified_search.?:request_format?" do
    json_only

    registries = {
      organisation_registry: organisation_registry,
      topic_registry: topic_registry,
      document_series_registry: document_series_registry,
      document_collection_registry: document_collection_registry,
      world_location_registry: world_location_registry,
      specialist_sector_registry: specialist_sector_registry,
    }
    registry_by_field = {
      organisations: organisation_registry,
      topics: topic_registry,
      document_series: document_series_registry,
      document_collections: document_collection_registry,
      world_locations: world_location_registry,
      specialist_sectors: specialist_sector_registry,
    }

    parser = SearchParameterParser.new(
      parse_query_string(request.query_string),
      current_index.mappings,
    )

    unless parser.valid?
      status 422
      return { error: parser.error }.to_json
    end

    searcher = UnifiedSearcher.new(unified_index, metasearch_index, registries, registry_by_field, suggester)
    searcher.search(parser.parsed_params).to_json
  end

  # To search a named index:
  #   /index_name/search?q=pie
  #
  # To search the primary index:
  #   /search?q=pie
  #
  # To scope a search to an organisation:
  #   /search?q=pie&organisation_slug=home-office
  #
  # To get the results in date order, rather than relevancy:
  #   /search?q=pie&sort=public_timestamp&order=desc
  #
  # The response looks like this:
  #
  #   {
  #     "total": 1,
  #     "results": [
  #       ...
  #     ],
  #     "spelling_suggestions": [
  #       ...
  #     ]
  #   }
  get "/?:index?/search.?:request_format?" do
    json_only

    organisation = params["organisation_slug"] == "" ? nil : params["organisation_slug"]
    result_set = current_index.search(@query,
      organisation: organisation,
      sort: params["sort"],
      order: params["order"])
    presenter_context = {
      organisation_registry: organisation_registry,
      topic_registry: topic_registry,
      document_series_registry: document_series_registry,
      document_collection_registry: document_collection_registry,
      world_location_registry: world_location_registry,
      spelling_suggestions: suggester.suggestions(@query)
    }
    presenter = ResultSetPresenter.new(result_set, presenter_context)
    presenter.present.to_json
  end

  # Perform an advanced search. Supports filters and pagination.
  #
  # Returns the first N results if no keywords or filters supplied
  #
  # Required parameters:
  #   per_page              - eg "40"
  #   page                  - eg "1"
  #
  # Optional parameters:
  #   order[fieldname]      - eg order[public_timestamp]=desc
  #   keywords              - eg "tax"
  #
  # Arbitrary "filter parameters", anything which is defined in the mappings
  # for the index is allowed. Examples:
  #   search_format_types[]        - eg "consultation"
  #   topics[]                     - eg "climate-change"
  #   organisations[]              - eg "cabinet-office"
  #   relevant_to_local_government - eg "1"
  #
  # If the field type is defined as "date", this is possible:
  #   fieldname[from]     - eg public_timestamp[from]="2013-04-30"
  #   fieldname[to]      - eg public_timestamp[to]="2013-04-30"
  #
  get "/:index/advanced_search.?:request_format?" do
    json_only

    # Using request.params because it is just the params from the request
    # rather than things added by Sinatra (eg splat, captures, index and format)
    result_set = current_index.advanced_search(request.params)
    ResultSetPresenter.new(result_set).present.to_json
  end

  get "/organisations.?:request_format?" do
    json_only

    organisations = organisation_registry.all
    OrganisationSetPresenter.new(organisations).present.to_json
  end

  # Insert (or overwrite) a document
  post "/?:index?/documents" do
    request.body.rewind
    documents = [JSON.parse(request.body.read)].flatten.map { |hash|
      current_index.document_from_hash(hash)
    }

    if settings.enable_queue
      current_index.add_queued(documents)
      json_result 202, "Queued"
    else
      simple_json_result(current_index.add(documents))
    end
  end

  post "/?:index?/commit" do
    simple_json_result(current_index.commit)
  end

  get "/?:index?/documents/*" do
    document = current_index.get(params["splat"].first)
    halt 404 unless document

    document.to_hash.to_json
  end

  delete "/?:index?/documents/*" do
    document_link = params["splat"].first

    if (type = get_type_from_request_body(request.body))
      id = document_link
    else
      type, id = current_index.link_to_type_and_id(document_link)
    end

    if settings.enable_queue
      current_index.delete_queued(type, id)
      json_result 202, "Queued"
    else
      simple_json_result(current_index.delete(type, id))
    end
  end

  def get_type_from_request_body(request_body)
    JSON.parse(request_body.read).fetch("_type", nil)
  rescue JSON::ParserError
    nil
  end

  # Update an existing document
  post "/?:index?/documents/*" do
    unless request.form_data?
      halt(
        415,
        {"Content-Type" => "text/plain"},
        "Amendments require application/x-www-form-urlencoded data"
      )
    end

    begin
      if settings.enable_queue
        current_index.amend_queued(params["splat"].first, request.POST)
        json_result 202, "Queued"
      else
        current_index.amend(params["splat"].first, request.POST)
        json_result 200, "OK"
      end
    rescue ArgumentError => e
      text_error e.message
    rescue Elasticsearch::DocumentNotFound
      halt 404
    end
  end

  delete "/?:index?/documents" do
    # DEPRECATED: the preferred way to do this is now through the
    # `rummager:switch_to_empty_index` Rake command

    if params["delete_all"]
      action = current_index.delete_all
    else
      action = current_index.delete(params["link"])
    end
    simple_json_result(action)
  end

  get "/_status" do
    status = {}
    status["queues"] = {}

    retries = Sidekiq::RetrySet.new.group_by(&:queue)
    scheduled = Sidekiq::ScheduledSet.new.group_by(&:queue)

    Sidekiq::Stats.new.queues.each do |queue_name, queue_size|
      retry_count = retries.fetch(queue_name, []).size
      scheduled_count = scheduled.fetch(queue_name, []).size
      status["queues"][queue_name] = {
        "jobs" => queue_size,
        "retries" => retry_count,
        "scheduled" => scheduled_count
      }
    end
    status.to_json
  end

end
