require "spec_helper"

module RankerTestHelpers
  include Fixtures::LearnToRankExplain

  def query
    "harry potter"
  end

  def search_results
    [
      {
        "_explanation" => default_explanation,
        "_score" => 0.98,
        "_source" => {
          "popularity" => 10,
          "title" => "More popular document",
        },
      },
      {
        "_explanation" => default_explanation,
        "_score" => 0.97,
        "_source" => {
          "popularity" => 5,
          "title" => "More relevant document",
        },
      },
    ]
  end

  def stub_request_to_ranker(examples, rank_response)
    stub_request(:post, "http://0.0.0.0:8501/v1/models/ltr:regress")
      .with(
        body: {
          signature_name: "regression",
          examples: examples,
        }.to_json,
        headers: {
          "Content-Type" => "application/json",
        },
      )
      .to_return(status: 200, body: { "results" => rank_response }.to_json)
  end

  def stub_ranker_is_unavailable
    stub_request(:post, "http://0.0.0.0:8501/v1/models/ltr:regress")
      .to_return(status: 500)
  end
end
