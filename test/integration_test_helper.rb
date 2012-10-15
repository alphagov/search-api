require "test_helper"
require "app"

module IntegrationFixtures
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
    Document.from_hash(sample_document_attributes)
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
    Document.from_hash(sample_recommended_document_attributes)
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

  def use_solr_for_primary_search
    # It invokes (according to mocha) "settings" on both Rummager and Sinatra::Application
    [app, Sinatra::Application].each do |thing|
      thing.settings.stubs(:backends).returns(
        primary: {
          type: "solr",
          server: "solr-test-server",
          port: 9999,
          path: "/solr/rummager"
        }
      )
    end
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
    # It invokes (according to mocha) "settings" on both Rummager and Sinatra::Application
    [app, Sinatra::Application].each do |thing|
      thing.settings.stubs(:backends).returns(hash)
    end
  end

  def delete_elasticsearch_index(index_name="rummager_test")
    begin
      RestClient.delete "http://localhost:9200/#{index_name}"
    rescue RestClient::Exception => exception
      raise unless exception.http_code == 404
    end
  end

  def reset_elasticsearch_index(index_name=:primary)
    admin = ElasticsearchAdminWrapper.new(
      settings.backends[index_name],
      settings.elasticsearch_schema
    )
    admin.ensure_index!
    admin.put_mappings
  end

  def assert_no_results
    assert_equal [], JSON.parse(last_response.body)
  end

  def stub_backend
    @backend_index = stub_everything("Chosen backend")
    app.any_instance.stubs(:backend).returns(@backend_index)
  end

  def stub_primary_and_secondary_searches
    @primary_search = stub_everything("Mainstream Solr wrapper")
    app.any_instance.stubs(:primary_search).returns(@primary_search)

    @secondary_search = stub_everything("Whitehall Solr wrapper")
    app.any_instance.stubs(:secondary_search).returns(@secondary_search)
  end
end
