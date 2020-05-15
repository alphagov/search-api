require "spec_helper"

RSpec.describe "ExpandsValuesFromSchemaTest" do
  it "extra fields decorated by schema" do
    commit_document(
      "govuk_test",
      {
        "link" => "/cma-cases/sample-cma-case",
        "case_type" => "mergers",
        "format" => "cma_case",
      },
      type: "cma_case",
    )

    get "/search?filter_document_type=cma_case&fields=case_type,description,title"
    first_result = parsed_response["results"].first

    expect(first_result["case_type"]).to eq([{ "label" => "Mergers", "value" => "mergers" }])
  end
end
