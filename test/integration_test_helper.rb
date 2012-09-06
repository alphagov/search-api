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

  def sample_section
    Section.new("bob")
  end
end

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

  def setup
    @primary_search = stub_everything("Mainstream Solr wrapper")
    Backends.any_instance.stubs(:primary_search).returns(@primary_search)

    @secondary_search = stub_everything("Whitehall Solr wrapper")
    Backends.any_instance.stubs(:secondary_search).returns(@secondary_search)
  end
end
