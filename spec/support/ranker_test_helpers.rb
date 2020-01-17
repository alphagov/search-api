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

  def stub_ranker_status_request
    stub_request(:any, "http://0.0.0.0:8501/v1/models/ltr")
  end

  def stub_ranker_container_doesnt_exist
    stub_ranker_status_request.to_return(status: 500)
  end

  def stub_ranker_requests_timeout
    stub_ranker_status_request.to_timeout
  end

  def stub_ranker_status_to_be_ok
    stub_ranker_status_request.to_return(
      status: 200,
      body: {
        "model_version_status": [
          {
            "version": "1",
            "state": "AVAILABLE",
            "status": {
              "error_code": "OK",
              "error_message": "",
            },
          },
        ],
      }.to_json,
    )
  end
end
