require "aws-sdk-s3"
require "date"
require "sinatra"
set :root, File.dirname(__FILE__)

require "rummager"
require "routes/content"
require "govuk_app_config"
require "healthcheck/sidekiq_queue_latencies_check"
require "healthcheck/elasticsearch_connectivity_check"

class Rummager < Sinatra::Application
  class AttemptToUseDefaultMainstreamIndex < StandardError; end

  Warden::Strategies.add :bearer_token, Warden::OAuth2::Strategies::Bearer
  Warden::OAuth2.configure { |config| config.token_model = Auth::GdsSso }
  Warden::Strategies.add :mock_bearer_token, Auth::MockStrategy
  # This ensures that post /unsubscribe is called no matter which method fails
  Warden::Manager.before_failure { |env, _| env["REQUEST_METHOD"] = "POST" }

  use Warden::Manager do |config|
    default_strategy = %w[development test].include?(ENV["RACK_ENV"]) ? "mock" : "real"
    mock = ENV.fetch("GDS_SSO_STRATEGY", default_strategy) == "mock"

    config.default_strategies mock ? [:mock_bearer_token] : [:bearer_token]
    config.failure_app = Rummager
    config.intercept_401 = false
  end

  # - Stop double slashes in URLs (even escaped ones) being flattened to single ones
  #
  # - Explicitly allow requests that are referred from other domains so we can link
  #   to the search API.
  #   JsonCsrf requires the referer to match this domain. This is one way to prevent
  #   browsers from being tricked into making a request that returns sensitive
  #   information or performs some dangerous action.
  #   In our case the only public API is search and there is no sensitive or
  #   personalised information in the response.
  set :protection, except: %i[path_traversal escaped_params frame_options json_csrf]

  def warden
    env["warden"]
  end

  def search_server
    SearchConfig.default_instance.search_server
  end

  def current_index
    search_server.index(index_name)
  rescue SearchIndices::NoSuchIndex
    halt(404)
  end

  def require_authentication
    warden.authenticate!
  end

  def prevent_access_to_govuk
    if index_name == "govuk"
      halt(403, "Actions to govuk index are not allowed via this endpoint, please use the message queue to update this index")
    end
  end

  def index_name
    @index_name ||= params["index"]
  end

  def text_error(content)
    halt 403, { "Content-Type" => "text/plain" }, content
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

  error Elasticsearch::Transport::Transport::Errors::RequestTimeout do
    halt(503, "Elasticsearch timed out")
  end

  error Elasticsearch::Transport::Transport::SnifferTimeoutError do
    halt(503, "Elasticsearch timed out")
  end

  error Redis::TimeoutError do
    halt(503, "Redis queue timed out")
  end

  error Indexer::BulkIndexFailure do
    halt(500, env["sinatra.error"].message)
  end

  error Search::Query::Error do
    halt(400, env["sinatra.error"].message)
  end

  error Index::ResponseValidator::ElasticsearchError do
    GovukError.notify(
      env["sinatra.error"],
      extra: {
        params: params,
      },
    )

    halt(500, env["sinatra.error"].message)
  end

  error ArgumentError do
    halt(400, env["sinatra.error"].message)
  end

  error Index::ResponseValidator::NotFound do
    halt(404, env["sinatra.error"].message)
  end

  error Rummager::AttemptToUseDefaultMainstreamIndex do
    GovukError.notify(
      env["sinatra.error"],
      extra: {
        params: params,
      },
    )
    halt(500, env["sinatra.error"].message)
  end


  # Return results for the GOV.UK site search
  #
  # For details, see doc/search-api.md
  ["/search.?:request_format?", "/api/search.?:request_format?"].each do |path|
    get path do
      json_only

      query_params = parse_query_string(request.query_string)

      begin
        results = SearchConfig.run_search(query_params)
      rescue BaseParameterParser::ParseError => e
        status 422
        return { error: e.error }.to_json
      end

      headers["Access-Control-Allow-Origin"] = "*"
      results.to_json
    end
  end

  # Batch return results for the GOV.UK site search
  ["/batch_search.?:request_format?", "/api/batch_search.?:request_format?"].each do |path|
    get path do
      json_only

      search_parameters = CGI::parse(request.query_string)
      parsed_searches_parameters = Hash.new { |hash, key| hash[key] = {} }
      search_parameters.each_pair do |parameter, values|
        parts = parameter.scan(/(?<=\[)\w+(?=\])/m)
        parsed_searches_parameters[parts[0]][parts[1]] = values
      end
      searches = parsed_searches_parameters.values
      results = []
      begin
        results = SearchConfig.run_batch_search(searches)
      rescue BaseParameterParser::ParseError => e
        status 422
        return { error: e.error }.to_json
      end

      headers["Access-Control-Allow-Origin"] = "*"
      { results: results }.to_json
    end
  end

  # Insert (or overwrite) a document
  post "/:index/documents" do
    require_authentication
    prevent_access_to_govuk
    request.body.rewind
    documents = [JSON.parse(request.body.read)].flatten.map { |hash|
      hash["document_type"] ||= hash.fetch("_type", "edition")
      hash["updated_at"] = DateTime.now
      current_index.document_from_hash(hash)
    }

    document_hashes = documents.map(&:elasticsearch_export)

    Indexer::BulkIndexWorker.perform_async(index_name, document_hashes)

    json_result 202, "Queued"
  end

  post "/v2/metasearch/documents" do
    require_authentication
    document = JSON.parse(request.body.read)

    inserter = MetasearchIndex::Inserter::V2.new(id: document["_id"], document: document)
    inserter.insert

    json_result 200, "Success"
  end

  post "/:index/commit" do
    require_authentication
    prevent_access_to_govuk
    simple_json_result(current_index.commit)
  end

  delete "/:index/documents/*" do
    require_authentication
    prevent_access_to_govuk
    document_link = params["splat"].first

    if (type = get_type_from_request_body(request.body))
      id = document_link
    else
      type, id = current_index.link_to_type_and_id(document_link)
    end

    Indexer::DeleteWorker.perform_async(index_name, type, id)

    json_result 202, "Queued"
  end

  delete "/v2/metasearch/documents/*" do
    require_authentication
    id = params["splat"].first

    deleter = MetasearchIndex::Deleter::V2.new(id: id)
    deleter.delete

    json_result 200, "Success"
  end

  def get_type_from_request_body(request_body)
    body = JSON.parse(request_body.read)
    body.fetch("document_type", body.fetch("_type", nil))
  rescue JSON::ParserError
    nil
  end

  # Update an existing document
  post "/:index/documents/*" do
    require_authentication
    prevent_access_to_govuk
    document_id = params["splat"].first
    updates = request.POST
    Indexer::AmendWorker.perform_async(index_name, document_id, updates)
    json_result 202, "Queued"
  end

  delete "/:index/documents" do
    require_authentication
    prevent_access_to_govuk
    if params["delete_all"]
      # No longer supported; instead use the
      # `search:switch_to_empty_index` Rake command
      halt 400
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
        "scheduled" => scheduled_count,
      }
    end
    status.to_json
  end

  # Healthcheck using govuk_app_config for Icinga alerts
  # See govuk_app_config/healthcheck for guidance on adding checks.
  get "/healthcheck" do
    checks = [
      GovukHealthcheck::SidekiqRedis,
      Healthcheck::SidekiqQueueLatenciesCheck,
      Healthcheck::ElasticsearchConnectivityCheck,
    ]

    GovukHealthcheck.healthcheck(checks).to_json
  end

  get "/sitemap.xml" do
    serve_from_s3("sitemap.xml")
  end

  get "/sitemaps/:sitemap" do |sitemap|
    serve_from_s3(sitemap)
  end

  def serve_from_s3(key)
    o = Aws::S3::Object.new(bucket_name: ENV["AWS_S3_BUCKET_NAME"], key: key)

    headers "Content-Type" => "application/xml",
            "Cache-Control" => "public",
            "Expires" => (Date.today + 1).rfc2822,
            "Last-Modified" => o.last_modified

    stream do |out|
      o.get.body.each { |chunk| out << chunk }
    end
  rescue Aws::S3::Errors::NotFound
    halt(404, "No such object")
  end

  # these endpoints are used to capture any usage of old endpoints which relied on a default index.
  # They can be removed once we are happy they are not being accessed.
  delete "/documents" do
    raise AttemptToUseDefaultMainstreamIndex
  end

  post "/documents/*" do
    raise AttemptToUseDefaultMainstreamIndex
  end

  delete "/documents/*" do
    raise AttemptToUseDefaultMainstreamIndex
  end

  post "/commit" do
    raise AttemptToUseDefaultMainstreamIndex
  end

  post "/documents" do
    raise AttemptToUseDefaultMainstreamIndex
  end

  post "/unauthenticated/?" do
    if env["HTTP_AUTHORIZATION"].to_s.start_with?("Bearer ")
      message = "Bearer token does not appear to be valid"
      bearer_error = "invalid_token"
    else
      message = "No bearer token was provided"
      bearer_error = "invalid_request"
    end

    headers = { "WWW-Authenticate" => %(Bearer error=#{bearer_error}) }
    body = { message: message }.to_json
    halt(401, headers, body)
  end
end
