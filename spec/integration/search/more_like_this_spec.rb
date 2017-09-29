require 'spec_helper'

RSpec.describe 'MoreLikeThisTest', tags: ['integration'] do
  it "returns_success" do
    get "/search?similar_to=/mainstream-1"

    expect(last_response).to be_ok
  end

  it "returns_no_results_without_documents" do
    get "/search?similar_to=/mainstream-1"

    expect(result_links).to be_empty
  end

  it "returns_results_from_mainstream_index" do
    add_sample_documents('mainstream_test', 15)

    get "/search?similar_to=/mainstream-1&count=20&start=0"

    expect(result_links).not_to include "/mainstream-1"
    expect(result_links.count).to eq(14)
  end

  it "returns_results_from_government_index" do
    add_sample_documents('government_test', 15)

    get "/search?similar_to=/government-1&count=20&start=0"

    expect(result_links).not_to include "/government-1"
    expect(result_links.count).to eq(14)
  end

  it "returns_similar_docs" do
    add_sample_documents('mainstream_test', 15)
    add_sample_documents('government_test', 15)

    get "/search?similar_to=/mainstream-1&count=50&start=0"

    # All mainstream documents (excluding the one we're using for comparison)
    # should be returned. The government links should also be returned as they
    # are similar enough (in this case, the test factories produce similar
    # looking records).
    expect(result_links).not_to include "/mainstream-1"
    expect(result_links.count).to eq(29)

    mainstream_results = result_links.select do |result|
      result.match(/mainstream-\d+/)
    end
    expect(mainstream_results.count).to eq(14)

    government_results = result_links.select do |result|
      result.match(/government-\d+/)
    end
    expect(government_results.count).to eq(15)
  end

private

  def result_links
    @_result_links ||= parsed_response["results"].map do |result|
      result["link"]
    end
  end
end
