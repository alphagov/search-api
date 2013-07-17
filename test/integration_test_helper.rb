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
      "humanized_format" => "Services",
      "presentation_format" => "local_transaction",
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
    unless /^[a-z]+_test($|-)/.match index_name
      raise InvalidTestIndex, index_name
    end
  end

  def stub_elasticsearch_settings(index_names = ["rummager_test"], default = nil)
    index_names.each do |n| check_index_name(n) end
    check_index_name(default) unless default.nil?

    @default_index_name = default || index_names.first

    app.settings.search_config.stubs(:elasticsearch).returns({
      "base_uri" => "http://localhost:9200",
      "index_names" => index_names
    })
    app.settings.stubs(:default_index_name).returns(@default_index_name)
    app.settings.stubs(:enable_queue).returns(false)
  end

  def stub_modified_schema
    schema = deep_copy(app.settings.search_config.elasticsearch_schema)

    # Allow the block to modify the schema copy directly
    yield schema

    app.settings.search_config.stubs(:elasticsearch_schema).returns(schema)
  end

  def enable_test_index_connections
    WebMock.disable_net_connect!(allow: %r{http://localhost:9200/(_search/scroll|_aliases|[a-z]+_test.*)})
  end

  def search_server
    app.settings.search_config.search_server
  end

  def create_test_index(group_name = @default_index_name)
    index_group = search_server.index_group(group_name)
    index = index_group.create_index
    index_group.switch_to(index)
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

end

class IntegrationTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods
  include IntegrationFixtures
  include ElasticsearchIntegration

  def app
    Rummager
  end

  def add_field_to_mappings(fieldname, type="string")
    stub_modified_schema do |schema|
      properties = schema["mappings"]["default"]["edition"]["properties"]
      properties.merge!({fieldname.to_s => { "type" => type, "index" => "not_analyzed" }})
    end
  end

  def assert_no_results
    assert_equal [], MultiJson.decode(last_response.body)
  end

  def stub_index
    s = stub("stub index")
    Rummager.any_instance.stubs(:current_index).returns(s)
    s
  end

private
  def deep_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end
end
