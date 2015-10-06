require "integration_test_helper"

class SpecialistDocumentSearchTest < IntegrationTest
  def setup
    stub_elasticsearch_settings
    reset_content_indexes_with_content
    add_sample_cma_case
  end

  def teardown
    clean_test_indexes
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
    }

    commit_document("mainstream_test", cma_case_attributes)
  end

  def test_extra_fields_decorated_by_schema
    get "/unified_search?filter_document_type=cma_case&fields=case_type,description,title"

    first_result = parsed_response["results"].first

    assert first_result.has_key? "case_type"
    assert_equal [{"label" => "Mergers", "value" => "mergers"}], first_result["case_type"]
  end
end
