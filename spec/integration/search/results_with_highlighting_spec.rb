require 'spec_helper'

RSpec.describe 'ResultsWithHighlightingTest', tags: ['integration'] do
  allow_elasticsearch_connection

  it "returns_highlighted_title" do
    commit_document("mainstream_test",
      "title" => "I am the result",
      "link" => "/some-nice-link",
    )

    get "/search?q=result&fields[]=title_with_highlighting"

    refute first_search_result.key?('title')
    assert_equal "I am the <mark>result</mark>",
      first_search_result['title_with_highlighting']
  end

  it "returns_highlighted_title_fallback" do
    commit_document("mainstream_test",
      "title" => "Thing without",
      "description" => "I am the result",
      "link" => "/some-nice-link",
    )

    get "/search?q=result&fields[]=title_with_highlighting"

    refute first_search_result.key?('title')
    assert_equal "Thing without",
      first_search_result['title_with_highlighting']
  end

  it "returns_highlighted_description" do
    commit_document("mainstream_test",
      "link" => "/some-nice-link",
      "description" => "This is a test search result of many results."
    )

    get "/search?q=result&fields[]=description_with_highlighting"

    refute first_search_result.key?('description')
    assert_equal "This is a test search <mark>result</mark> of many <mark>results</mark>.",
      first_search_result['description_with_highlighting']
  end

  it "returns_documents_html_escaped" do
    commit_document("mainstream_test",
      "title" => "Escape & highlight my title",
      "link" => "/some-nice-link",
      "description" => "Escape & highlight the description as well."
    )

    get "/search?q=highlight&fields[]=title_with_highlighting,description_with_highlighting"

    assert_equal "Escape &amp; <mark>highlight</mark> the description as well.",
      first_search_result['description_with_highlighting']
    assert_equal "Escape &amp; <mark>highlight</mark> my title",
      first_search_result['title_with_highlighting']
  end

  it "returns_truncated_correctly_where_result_at_start_of_description" do
    commit_document("mainstream_test",
      "link" => "/some-nice-link",
      "description" => "word " + ("something " * 200)
    )

    get "/search?q=word&fields[]=description_with_highlighting"
    description = first_search_result['description_with_highlighting']

    assert description.starts_with?("<mark>word</mark>")
    assert description.ends_with?("…")
  end

  it "returns_truncated_correctly_where_result_at_end_of_description" do
    commit_document("mainstream_test",
      "link" => "/some-nice-link",
      "description" => ("something " * 200) + " word"
    )

    get "/search?q=word&fields[]=description_with_highlighting"
    description = first_search_result['description_with_highlighting']

    assert description.starts_with?("…")
    assert description.size < 350
  end

  it "returns_truncated_correctly_where_result_in_middle_of_description" do
    commit_document("mainstream_test",
      "link" => "/some-nice-link",
      "description" => ("something " * 200) + " word " + ("something " * 200)
    )

    get "/search?q=word&fields[]=description_with_highlighting"
    description = first_search_result['description_with_highlighting']

    assert description.ends_with?("…")
    assert description.starts_with?("…")
  end

private

  def first_search_result
    @first_search_result ||= parsed_response['results'].first
  end
end
