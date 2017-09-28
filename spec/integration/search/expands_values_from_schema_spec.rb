require 'spec_helper'

RSpec.describe 'ExpandsValuesFromSchemaTest', tags: ['integration'] do
  allow_elasticsearch_connection

  it "extra_fields_decorated_by_schema" do
    commit_document("mainstream_test", {
      "link" => "/cma-cases/sample-cma-case",
      "case_type" => "mergers",
    }, type: "cma_case")

    get "/search?filter_document_type=cma_case&fields=case_type,description,title"
    first_result = parsed_response["results"].first

    assert_equal [{ "label" => "Mergers", "value" => "mergers" }], first_result["case_type"]
  end
end
