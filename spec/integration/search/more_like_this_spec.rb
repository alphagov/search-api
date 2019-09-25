require "spec_helper"

RSpec.describe "MoreLikeThisTest" do
  it "returns success" do
    get "/search?similar_to=/govuk-1"

    expect(last_response).to be_ok
  end

  it "returns no results without documents" do
    get "/search?similar_to=/govuk-1"

    expect(result_links).to be_empty
  end

  it "returns results from mainstream index" do
    add_sample_documents("govuk_test", 15)

    get "/search?similar_to=/govuk-1&count=20&start=0"

    expect(result_links).not_to include "/govuk-1"
    expect(result_links.count).to eq(14)
  end

  it "returns results from government index" do
    add_sample_documents("government_test", 15)

    get "/search?similar_to=/government-1&count=20&start=0"

    expect(result_links).not_to include "/government-1"
    expect(result_links.count).to eq(14)
  end

  it "returns similar docs" do
    add_sample_documents("govuk_test", 15)
    add_sample_documents("government_test", 15)

    get "/search?similar_to=/govuk-1&count=50&start=0"

    # All govuk documents (excluding the one we're using for comparison)
    # should be returned. The government links should also be returned as they
    # are similar enough (in this case, the test factories produce similar
    # looking records).
    expect(result_links).not_to include "/govuk-1"
    expect(result_links.count).to eq(29)

    govuk_results = result_links.select do |result|
      result.match(/govuk-\d+/)
    end
    expect(govuk_results.count).to eq(14)

    government_results = result_links.select do |result|
      result.match(/government-\d+/)
    end
    expect(government_results.count).to eq(15)
  end

private

  def result_links
    @result_links ||= parsed_response["results"].map do |result|
      result["link"]
    end
  end
end
