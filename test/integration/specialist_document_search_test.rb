require "integration_test_helper"
require "rest-client"
require_relative "multi_index_test"

class SpecialistDocumentSearchTest < MultiIndexTest
  def setup
    super
    add_sample_cma_case
  end

  def add_sample_cma_case
    # Do the thing
    cma_case_attributes = {
      "title" => "Sample CMA Case",
      "description" => "The CMA is investigating everyone",
      "link" => "/cma-cases/sample-cma-case",
      "indexable_content" => "Something something important content",
      "case_state" => "open",
      "market_sector" => "energy",
      "opened_date" => "2014-08-22",
      "case_type" => "mergers",
      "_type" => "cma_case",
      "section" => ["1"],
    }

    insert_document("mainstream_test", cma_case_attributes)
  end

  def test_extra_fields_decorated_by_schema
    get "/unified_search?filter_document_type=cma_case&fields=case_type,description,title"

    first_result = parsed_response["results"].first

    assert first_result.has_key? "case_type"
    assert first_result["case_type"] == [{"label" => "Mergers", "value" => "mergers"}]
  end
end
