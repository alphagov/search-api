require "test_helper"
require "app"
require "elasticsearch/search_server"

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

  def sample_section
    Section.new("bob")
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

    @default_index = default || index_names.first
    app.settings.stubs(:elasticsearch).returns({
      "base_uri" => "http://localhost:9200",
      "index_names" => index_names,
      "default_index" => @default_index
    })
  end

  def enable_test_index_connections
    WebMock.disable_net_connect!(allow: %r{http://localhost:9200/(_aliases|[a-z]+_test.*)})
  end

  def search_server
    Elasticsearch::SearchServer.new(
      app.settings.elasticsearch["base_uri"],
      app.settings.elasticsearch_schema,
      app.settings.elasticsearch_schema["index_names"]
    )
  end

  def create_test_index(group_name = @default_index)
    index_group = search_server.index_group(group_name)
    index = index_group.create_index
    index_group.switch_to(index)
  end

  def try_remove_test_index(index_name = @default_index)
    check_index_name(index_name)
    RestClient.delete "http://localhost:9200/#{CGI.escape(index_name)}"
  rescue RestClient::ResourceNotFound
    # Index doesn't exist: that's fine
  end

  def clean_index_group(group_name = @default_index)
    check_index_name(group_name)
    search_server.index_group(group_name).clean
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
    schema = deep_copy(settings.elasticsearch_schema)
    properties = schema["mappings"]["default"]["edition"]["properties"]
    properties.merge!({fieldname.to_s => { "type" => type, "index" => "not_analyzed" }})

    app.settings.stubs(:elasticsearch_schema).returns(schema)
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
