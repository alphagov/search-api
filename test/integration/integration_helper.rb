# encoding: utf-8
require_relative "../test_helper"
require_relative "../../lib/document"
require_relative "../../lib/section"
require_relative "../../app"

module IntegrationFixtures
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

  def setup
    @solr = stub_everything("Solr wrapper")
    SolrWrapper.stubs(:new).returns(@solr)
  end
end