require "test_helper"
require "app"

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

require "elasticsearch_admin_wrapper"

class IntegrationTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include IntegrationFixtures

  def app
    Rummager
  end

  def disable_secondary_search
    @secondary_search.stubs(:search).returns([])
  end

  def use_elasticsearch_for_primary_search
    stub_backends_with(primary: {
          type: "elasticsearch",
          server: "localhost",
          port: 9200,
          index_name: "rummager_test"
        })
  end

  def stub_backends_with(hash)
    app.settings.stubs(:backends).returns(hash)
  end

  def add_field_to_mappings(fieldname, type="string")
    schema = deep_copy(settings.elasticsearch_schema)
    properties = schema["mappings"]["default"]["edition"]["properties"]
    properties.merge!({fieldname.to_s => { "type" => type, "index" => "not_analyzed" }})

    app.settings.stubs(:elasticsearch_schema).returns(schema)
  end

  def reset_elasticsearch_index(index_name=:primary)
    admin_wrapper(index_name).tap do |admin|
      admin.ensure_index!
      admin.put_mappings
    end
  end

  def update_elasticsearch_index(index_name=:primary)
    admin_wrapper(index_name).tap do |admin|
      admin.ensure_index
      admin.put_mappings
    end
  end

  def assert_no_results
    assert_equal [], MultiJson.decode(last_response.body)
  end

  def stub_backend
    @backend_index = stub_everything("Chosen backend")
    app.any_instance.stubs(:backend).returns(@backend_index)
  end

  def stub_primary_and_secondary_searches
    @primary_search = stub_everything("Mainstream wrapper")
    app.any_instance.stubs(:primary_search).returns(@primary_search)

    @secondary_search = stub_everything("Whitehall wrapper")
    app.any_instance.stubs(:secondary_search).returns(@secondary_search)
  end

  def wrapper_for(index_name, mappings_fixture_file = "elasticsearch_schema.fixture.yml")
    ElasticsearchAdminWrapper.new(
      {
        type: "elasticsearch",
        server: "localhost",
        port: 9200,
        index_name: index_name
      },
      load_yaml_fixture(mappings_fixture_file)
    )
  end

private
  def deep_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end

  def admin_wrapper(index_name, mappings_fixture_file = nil)
    schema = mappings_fixture_file ? load_yaml_fixture(mappings_fixture_file) : app.settings.elasticsearch_schema
    ElasticsearchAdminWrapper.new(
      app.settings.backends[index_name],
      schema
    )
  end
end
