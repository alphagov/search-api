require "integration_test_helper"

class ExpandsValuesFromSchemaTest < IntegrationTest
  def setup
    stub_elasticsearch_settings
    reset_content_indexes
  end

  def teardown
    clean_test_indexes
  end

  def test_extra_fields_decorated_by_schema
    commit_document("mainstream_test", {
      "link" => "/cma-cases/sample-cma-case",
      "case_type" => "mergers",
      "_type" => "cma_case",
    })

    get "/unified_search?filter_document_type=cma_case&fields=case_type,description,title"
    first_result = parsed_response["results"].first

    assert_equal [{ "label" => "Mergers", "value" => "mergers" }], first_result["case_type"]
  end
end
