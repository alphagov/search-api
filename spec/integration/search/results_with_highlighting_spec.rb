require 'spec_helper'

RSpec.describe 'ResultsWithHighlightingTest' do
  with_ab_variants do
    it "returns_highlighted_title" do
      commit_document(
        "mainstream_test",
        "title" => "I am the result",
        "link" => "/some-nice-link",
      )

      get_with_variant "/search?q=result&fields[]=title_with_highlighting"

      expect(first_search_result.key?('title')).to be_falsey
      expect(first_search_result['title_with_highlighting']).to eq("I am the <mark>result</mark>")
    end

    it "returns_highlighted_title_fallback" do
      commit_document(
        "mainstream_test",
        "title" => "Thing without",
        "description" => "I am the result",
        "link" => "/some-nice-link",
      )

      get_with_variant "/search?q=result&fields[]=title_with_highlighting"

      expect(first_search_result.key?('title')).to be_falsey
      expect(first_search_result['title_with_highlighting']).to eq("Thing without")
    end

    it "returns_highlighted_description" do
      commit_document(
        "mainstream_test",
        "link" => "/some-nice-link",
        "description" => "This is a test search result of many results.",
      )

      get_with_variant "/search?q=result&fields[]=description_with_highlighting"

      expect(first_search_result.key?('description')).to be_falsey
      expect("This is a test search <mark>result</mark> of many <mark>results</mark>.").to eq(
        first_search_result['description_with_highlighting']
      )
    end

    it "returns_documents_html_escaped" do
      commit_document(
        "mainstream_test",
        "title" => "Escape & highlight my title",
        "link" => "/some-nice-link",
        "description" => "Escape & highlight the description as well.",
      )

      get_with_variant "/search?q=highlight&fields[]=title_with_highlighting,description_with_highlighting"

      expect("Escape &amp; <mark>highlight</mark> the description as well.").to eq(
        first_search_result['description_with_highlighting']
      )
      expect("Escape &amp; <mark>highlight</mark> my title").to eq(
        first_search_result['title_with_highlighting']
      )
    end

    it "returns_truncated_correctly_where_result_at_start_of_description" do
      commit_document(
        "mainstream_test",
        "link" => "/some-nice-link",
        "description" => "word " + ("something " * 200),
      )

      get_with_variant "/search?q=word&fields[]=description_with_highlighting"
      description = first_search_result['description_with_highlighting']

      expect(description.starts_with?("<mark>word</mark>")).to be_truthy
      expect(description.ends_with?("…")).to be_truthy
    end

    it "returns_truncated_correctly_where_result_at_end_of_description" do
      commit_document(
        "mainstream_test",
        "link" => "/some-nice-link",
        "description" => ("something " * 200) + " word",
      )

      get_with_variant "/search?q=word&fields[]=description_with_highlighting"
      description = first_search_result['description_with_highlighting']

      expect(description.starts_with?("…")).to be_truthy
      expect(description.size < 350).to be_truthy
    end

    it "returns_truncated_correctly_where_result_in_middle_of_description" do
      commit_document(
        "mainstream_test",
        "link" => "/some-nice-link",
        "description" => ("something " * 200) + " word " + ("something " * 200),
      )

      get_with_variant "/search?q=word&fields[]=description_with_highlighting"
      description = first_search_result['description_with_highlighting']

      expect(description.ends_with?("…")).to be_truthy
      expect(description.starts_with?("…")).to be_truthy
    end
  end

private

  def first_search_result
    @first_search_result ||= parsed_response['results'].first
  end
end
