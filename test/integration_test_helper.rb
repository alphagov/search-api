require "test_helper"
require 'slimmer/test'
require "app"
require "nokogiri"

require "htmlentities"

module ResponseAssertions
  def assert_response_text(needle)
    haystack = HTMLEntities.new.decode(last_response.body.gsub(/<[^>]+>/, " ").gsub(/\s+/, " "))
    message = "Expected to find #{needle.inspect} in\n#{haystack}"
    assert haystack.include?(needle), message
  end

  def assert_links(link_map)
    doc = Nokogiri::HTML.parse(last_response.body)
    link_map.each do |text, href|
      assert doc.xpath("//a[text()='#{text.gsub("'", "\\'")}']").any? { |link|
        link["href"] == href
      }
    end
  end

  def refute_links(link_map)
    doc = Nokogiri::HTML.parse(last_response.body)
    link_map.each do |text, href|
      assert_false doc.xpath("//a[text()='#{text.gsub("'", "\\'")}']").any? { |link|
        link["href"] == href
      }
    end
  end

end

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
  include ResponseAssertions
  include IntegrationFixtures

  def app
    Sinatra::Application
  end

  def disable_secondary_search
    @secondary_search.stubs(:search).returns([])
  end

  def use_solr_for_primary_search
    settings.stubs(:backends).returns(
      primary: {
        type: "solr",
        server: "solr-test-server",
        port: 9999,
        path: "/solr/rummager"
      }
    )
  end

  def use_elasticsearch_for_primary_search
    settings.stubs(:backends).returns(
      primary: {
        type: "elasticsearch",
        server: "localhost",
        port: 9200,
        index_name: "rummager_test"
      }
    )
  end

  def delete_elasticsearch_index
    begin
      RestClient.delete "http://localhost:9200/rummager_test"
    rescue RestClient::Exception => exception
      raise unless exception.http_code == 404
    end
  end

  def reset_elasticsearch_index
    admin = ElasticsearchAdminWrapper.new(
      settings.backends[:primary],
      settings.elasticsearch_schema
    )
    admin.create_index!
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
