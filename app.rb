%w[ lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end

require "sinatra"
require 'yajl/json_gem'
require "multi_json"
require "csv"
require "statsd"

require "document"
require "result_set_presenter"
require "organisation_set_presenter"
require "document_series_registry"
require "organisation_registry"
require "topic_registry"
require "world_location_registry"
require "elasticsearch/index"
require "elasticsearch/search_server"

require_relative "config"
require_relative "helpers"

class Rummager < Sinatra::Application
  def self.statsd
    @@statsd ||= Statsd.new("localhost").tap do |c|
      c.namespace = ENV["GOVUK_STATSD_PREFIX"].to_s
    end
  end

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
    @@document_series_registry ||= DocumentSeriesRegistry.new(search_server.index(index_name)) if index_name
  end

  def organisation_registry
    index_name = settings.search_config.organisation_registry_index
    @@organisation_registry ||= OrganisationRegistry.new(search_server.index(index_name)) if index_name
  end

  def topic_registry
    index_name = settings.search_config.topic_registry_index
    @@topic_registry ||= TopicRegistry.new(search_server.index(index_name)) if index_name
  end

  def world_location_registry
    index_name = settings.search_config.world_location_registry_index
    @@world_location_registry ||= WorldLocationRegistry.new(search_server.index(index_name)) if index_name
  end

  def indices_for_sitemap
    settings.search_config.index_names.map do |index_name|
      search_server.index(index_name)
    end
  end

  def text_error(content)
    halt 403, {"Content-Type" => "text/plain"}, content
  end

  def json_only
    unless [nil, "json"].include? params[:format]
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

  # To search a named index:
  #   /index_name/search?q=pie
  #
  # To search the primary index:
  #   /search?q=pie
  #
  # To scope a search to an organisation:
  #   /search?q=pie&organisation_slug=home-office
  #
  # To get the results in a Hash:
  #   /search?q=pie&response_style=hash
  #
  #   {
  #     "total": 1,
  #     "results": [
  #       ...
  #     ]
  #   }
  get "/?:index?/search.?:format?" do
    json_only

    query = params["q"].to_s.gsub(/[\u{0}-\u{1f}]/, "").strip

    if query == ""
      expires 3600, :public
      halt 404
    end

    expires 3600, :public if query.length < 20
    organisation = params["organisation_slug"].blank? ? nil : params["organisation_slug"]
    result_set = current_index.search(query, organisation)
    presenter_context = {
      organisation_registry: organisation_registry,
      topic_registry: topic_registry,
      document_series_registry: document_series_registry,
      world_location_registry: world_location_registry
    }
    presenter = ResultSetPresenter.new(result_set, presenter_context)
    if params["response_style"] == "hash"
      presenter.present_with_total
    else
      presenter.present
    end
  end

  get "/:index/advanced_search.?:format?" do
    json_only

    result_set = current_index.advanced_search(request.params)
    ResultSetPresenter.new(result_set).present_with_total
  end

  get "/organisations.?:format" do
    json_only

    organisations = organisation_registry.all
    OrganisationSetPresenter.new(organisations).present_with_total
  end

  post "/?:index?/documents" do
    request.body.rewind
    documents = [MultiJson.decode(request.body.read)].flatten.map { |hash|
      current_index.document_from_hash(hash)
    }

    simple_json_result(current_index.add(documents))
  end

  post "/?:index?/commit" do
    simple_json_result(current_index.commit)
  end

  get "/?:index?/documents/*" do
    document = current_index.get(params["splat"].first)
    halt 404 unless document

    MultiJson.encode document.to_hash
  end

  delete "/?:index?/documents/*" do
    simple_json_result(current_index.delete(params["splat"].first))
  end

  post "/?:index?/documents/*" do
    unless request.form_data?
      halt(
        415,
        {"Content-Type" => "text/plain"},
        "Amendments require application/x-www-form-urlencoded data"
      )
    end
    document = current_index.get(params["splat"].first)
    halt 404 unless document
    text_error "Cannot change document links" if request.POST.include? "link"

    # Note: this expects application/x-www-form-urlencoded data, not JSON
    request.POST.each_pair do |key, value|
      if document.has_field?(key)
        document.set key, value
      else
        text_error "Unrecognised field '#{key}'"
      end
    end
    simple_json_result(current_index.add([document]))
  end

  delete "/?:index?/documents" do
    if params["delete_all"]
      action = current_index.delete_all
    else
      action = current_index.delete(params["link"])
    end
    simple_json_result(action)
  end
end
