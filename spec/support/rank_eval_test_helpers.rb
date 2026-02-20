require "csv"
require "spec_helper"

module RankEvalTestHelpers
  def mock_judgement_csv
    CSV.generate do |csv|
      csv << %w[query rating link score]
      csv << ["harry potter", "relevant", "/harry-potter", 3]
      # use /government to test fetching alias for government index
      csv << ["passport", "relevant", "/government/renew-a-passport", 3]
      # add repeated row to test ignore_extra_judgements
      csv << ["passport", "near", "/government/renew-a-passport", 2]
    end
  end

  def rank_eval_expected_output
    <<~OUTPUT
      harry potter: 1
      passport: 0
      ---
      overall score: 0.5
    OUTPUT
  end

  def stub_rank_eval_request
    es_source = ENV["ELASTICSEARCH_URI"] || "http://localhost:9200"
    stub_request(:post, "#{es_source}/*/_rank_eval")
      .to_return(
        status: 200,
        body: {
          metric_score: 0.5,
          details: {
            "harry potter": {
              metric_score: 1,
              unrated_docs: [{ _index: "govuk_test", _id: "/who-is-harry-potter" }],
              hits: [
                {
                  hit: {
                    _index: "govuk_test",
                    _id: "/harry-potter",
                    _type: "generic-document",
                    _score: 0,
                  },
                  rating: 1,
                },
              ],
            },
            passport: {
              metric_score: 0,
              unrated_docs: [{ _index: "govuk_test", _id: "/universal_credit" }],
              hits: [
                {
                  hit: {
                    _index: "govuk_test",
                    _id: "/take-pet-abroad",
                    _type: "generic-document",
                    _score: 0,
                  },
                  rating: 0,
                },
              ],
            },
          },
        }.to_json,
        headers: {
          "Content-Type" => "application/json",
        },
      )
  end
end
