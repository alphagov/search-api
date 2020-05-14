require "spec_helper"

RSpec.describe "BoosterTest" do
  it "service manual formats are weighted down" do
    commit_document(
      "govuk_test",
      "title" => "Agile is good",
      "link" => "/agile-is-good",
      "format" => "service_manual_guide",
    )

    commit_document(
      "govuk_test",
      "title" => "Being agile is good",
      "link" => "/being-agile-is-good",
      "format" => "service_manual_topic",
    )

    commit_document(
      "govuk_test",
      "title" => "Can we be agile?",
      "link" => "/can-we-be-agile",
      "format" => "cma_case",
    )

    get "/search?q=agile"

    expect(result_titles).to eq(["Can we be agile?", "Agile is good", "Being agile is good"])
  end

  def result_titles
    parsed_response["results"].map do |result|
      result["title"]
    end
  end
end
