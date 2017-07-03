require "integration_test_helper"

class BoosterTest < IntegrationTest
  def test_service_manual_formats_are_weighted_down
    commit_document("mainstream_test",
      title: "Agile is good",
      link: "/agile-is-good",
      format: "service_manual_guide",
    )

    commit_document("mainstream_test",
      title: "Being agile is good",
      link: "/being-agile-is-good",
      format: "service_manual_topic",
    )

    commit_document("mainstream_test",
      title: "Can we be agile?",
      link: "/can-we-be-agile",
    )

    get "/search?q=agile"

    assert_equal ["Can we be agile?", "Agile is good", "Being agile is good"],
      result_titles
  end

  def result_titles
    parsed_response['results'].map do |result|
      result['title']
    end
  end
end
