require "test_helper"
require 'slimmer/test'
require "app"

require "htmlentities"

module ResponseAssertions
  def assert_response_text(needle)
    haystack = HTMLEntities.new.decode(last_response.body.gsub(/<[^>]+>/, " ").gsub(/\s+/, " "))
    message = "Expected to find #{needle.inspect} in\n#{haystack}"
    assert haystack.include?(needle), message
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
end

class IntegrationTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include ResponseAssertions
  include IntegrationFixtures

  def app
    Sinatra::Application
  end

  def setup
    @primary_solr = stub_everything("Mainstream Solr wrapper")
    @secondary_solr = stub_everything("Whitehall Solr wrapper")

    DelSolr::Client.stubs(:new).with(settings.solr).returns(:mainstream_client)
    DelSolr::Client.stubs(:new).with(settings.secondary_solr).returns(:whitehall_client)

    SolrWrapper.stubs(:new).with(:mainstream_client, anything, anything).returns(@primary_solr)
    SolrWrapper.stubs(:new).with(:whitehall_client, anything, anything).returns(@secondary_solr)
  end
end
