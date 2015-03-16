require "test_helper"
require "app"
require "elasticsearch/search_server"
require "sidekiq/testing/inline"  # Make all queued jobs run immediately

module IntegrationFixtures
  include Fixtures::DefaultMappings

  def sample_document_attributes
    {
      "title" => "TITLE1",
      "description" => "DESCRIPTION",
      "format" => "local_transaction",
      "section" => "life-in-the-uk",
      "link" => "/URL"
    }
  end

  def sample_document
    Document.from_hash(sample_document_attributes, default_mappings)
  end

  def sample_recommended_document_attributes
    {
      "title" => "TITLE1",
      "description" => "DESCRIPTION",
      "format" => "recommended-link",
      "link" => "/URL"
    }
  end

  def sample_recommended_document
    Document.from_hash(sample_recommended_document_attributes, default_mappings)
  end
end

class InvalidTestIndex < ArgumentError; end

module ElasticsearchIntegration
  # Make sure that we're dealing with a test index (of the form <foo>_test)
  def check_index_name(index_name)
    unless /^[a-z_-]+(_|-)test($|-)/.match index_name
      raise InvalidTestIndex, "#{index_name} is not a valid test index name"
    end
  end

  def stub_elasticsearch_settings(content_index_names = ["mainstream_test"], default = nil)
    metasearch_index_name = "metasearch_test"
    auxiliary_index_names=["page-traffic_test", metasearch_index_name]
    (content_index_names + auxiliary_index_names).each do |n|
      check_index_name(n)
    end
    check_index_name(default) unless default.nil?

    @content_indexes = content_index_names
    @default_index_name = default || content_index_names.first
    @auxiliary_indexes = auxiliary_index_names

    app.settings.search_config.stubs(:elasticsearch).returns({
      "base_uri" => "http://localhost:9200",
      "content_index_names" => content_index_names,
      "auxiliary_index_names" => auxiliary_index_names,
      "govuk_index_names" => content_index_names,
      "metasearch_index_name" => metasearch_index_name,
    })
    app.settings.stubs(:default_index_name).returns(@default_index_name)
    app.settings.stubs(:enable_queue).returns(false)
  end

  def enable_test_index_connections
    WebMock.disable_net_connect!(allow: %r{http://localhost:9200/(_search/scroll|_aliases|[a-z_-]+(_|-)test.*)})
  end

  def search_server
    app.settings.search_config.search_server
  end

  def create_test_index(group_name = @default_index_name)
    index_group = search_server.index_group(group_name)
    index = index_group.create_index
    index_group.switch_to(index)
  end

  def create_test_indexes
    (@auxiliary_indexes + @content_indexes).each do |index|
      create_test_index(index)
    end
  end

  def clean_test_indexes
    (@auxiliary_indexes + @content_indexes).each do |index|
      clean_index_group(index)
    end
  end

  def insert_stub_popularity_data(path)
    document_atts = {
      "path_components" => path,
      "rank_14" => 10,
    }

    RestClient.post "http://localhost:9200/page-traffic_test/page-traffic/#{CGI.escape(path)}", document_atts.to_json
    RestClient.post "http://localhost:9200/page-traffic_test/_refresh", nil
  end

  def try_remove_test_index(index_name = @default_index_name)
    check_index_name(index_name)
    RestClient.delete "http://localhost:9200/#{CGI.escape(index_name)}"
  rescue RestClient::ResourceNotFound
    # Index doesn't exist: that's fine
  end

  def clean_index_group(group_name = @default_index_name)
    check_index_name(group_name)
    index_group = search_server.index_group(group_name)
    # Delete any indices left over from switching
    index_group.clean
    # Clean up the test index too, to avoid the possibility of inter-dependent
    # tests. It also keeps the index view cleaner.
    if index_group.current.exists?
      index_group.send(:delete, index_group.current.real_name)
    end
  end

  def clean_popularity_index
    try_remove_test_index 'page-traffic_test'
  end
end

class IntegrationTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods
  include IntegrationFixtures
  include ElasticsearchIntegration

  def app
    Rummager
  end

  def assert_no_results
    assert_equal [], JSON.parse(last_response.body)["results"]
  end

  def stub_index
    return @s if @s
    @s = stub("stub index")
    Rummager.any_instance.stubs(:current_index).returns(@s)
    Rummager.any_instance.stubs(:unified_index).returns(@s)
    @s
  end

  def stub_metasearch_index
    return @ms if @ms
    @ms = stub("stub metasearch index")
    Rummager.any_instance.stubs(:metasearch_index).returns(@ms)
    @ms
  end

private
  def deep_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end
end
