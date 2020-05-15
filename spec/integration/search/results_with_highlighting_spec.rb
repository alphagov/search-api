require "spec_helper"

RSpec.describe "ResultsWithHighlightingTest" do
  it "doesn't break without keywords" do
    commit_document(
      "government_test",
      "title" => "I am the result",
      "link" => "/some-nice-link",
    )

    get "/search?fields[]=title_with_highlighting"

    expect(first_search_result).not_to be_key("title")
    expect(first_search_result["title_with_highlighting"]).to eq("I am the result")
  end

  it "returns highlighted title" do
    commit_document(
      "government_test",
      "title" => "I am the result",
      "link" => "/some-nice-link",
    )

    get "/search?q=result&fields[]=title_with_highlighting"

    expect(first_search_result).not_to be_key("title")
    expect(first_search_result["title_with_highlighting"]).to eq("I am the <mark>result</mark>")
  end

  it "returns highlighted title fallback" do
    commit_document(
      "government_test",
      "title" => "Thing without",
      "description" => "I am the result",
      "link" => "/some-nice-link",
    )

    get "/search?q=result&fields[]=title_with_highlighting"

    expect(first_search_result).not_to be_key("title")
    expect(first_search_result["title_with_highlighting"]).to eq("Thing without")
  end

  it "returns highlighted description" do
    commit_document(
      "government_test",
      "link" => "/some-nice-link",
      "description" => "This is a test search result of many results.",
    )

    get "/search?q=result&fields[]=description_with_highlighting"

    expect(first_search_result).not_to be_key("description")
    expect("This is a test search <mark>result</mark> of many <mark>results</mark>.").to eq(
      first_search_result["description_with_highlighting"],
    )
  end

  it "highlights mixed quoted/unquoted queries" do
    commit_document(
      "government_test",
      "link" => "/some-nice-link",
      "description" => "This is a test search result of many results.",
    )

    get "/search?q=\"search+result\"+test&fields[]=description_with_highlighting"

    expect(first_search_result).not_to be_key("description")
    expect("This is a <mark>test</mark> <mark>search</mark> <mark>result</mark> of many results.").to eq(
      first_search_result["description_with_highlighting"],
    )
  end

  it "highlights quoted queries in their entirety (other than stopwords)" do
    commit_document(
      "government_test",
      "link" => "/some-nice-link",
      "description" => "The ministry of magic is a magic ministry.",
    )

    get "/search?q=\"ministry of magic\"&fields[]=description_with_highlighting"

    expect(first_search_result).not_to be_key("description")
    expect("The <mark>ministry</mark> of <mark>magic</mark> is a magic ministry.").to eq(
      first_search_result["description_with_highlighting"],
    )
  end

  it "highlights synonyms" do
    commit_document(
      "government_test",
      "link" => "/some-nice-link",
      "description" => "This is one (1) page.",
    )

    get "/search?q=one&fields[]=description_with_highlighting"

    expect(first_search_result).not_to be_key("description")
    expect("This is <mark>one</mark> (<mark>1</mark>) page.").to eq(
      first_search_result["description_with_highlighting"],
    )
  end

  it "doesn't highlight synonyms if they're disabled" do
    commit_document(
      "government_test",
      "link" => "/some-nice-link",
      "description" => "This is one (1) page.",
    )

    get "/search?q=one&fields[]=description_with_highlighting&debug=disable_synonyms"

    expect(first_search_result).not_to be_key("description")
    expect("This is <mark>one</mark> (1) page.").to eq(
      first_search_result["description_with_highlighting"],
    )
  end

  it "returns documents html escaped" do
    commit_document(
      "government_test",
      "title" => "Escape & highlight my title",
      "link" => "/some-nice-link",
      "description" => "Escape & highlight the description as well.",
    )

    get "/search?q=highlight&fields[]=title_with_highlighting,description_with_highlighting"

    expect("Escape &amp; <mark>highlight</mark> the description as well.").to eq(
      first_search_result["description_with_highlighting"],
    )
    expect("Escape &amp; <mark>highlight</mark> my title").to eq(
      first_search_result["title_with_highlighting"],
    )
  end

  it "returns truncated correctly where result at start of description" do
    commit_document(
      "government_test",
      "link" => "/some-nice-link",
      "description" => "word " + ("something " * 200),
    )

    get "/search?q=word&fields[]=description_with_highlighting"
    description = first_search_result["description_with_highlighting"]

    expect(description).to be_starts_with("<mark>word</mark>")
    expect(description).to be_ends_with("…")
  end

  it "returns truncated correctly where result at end of description" do
    commit_document(
      "government_test",
      "link" => "/some-nice-link",
      "description" => ("something " * 200) + " word",
    )

    get "/search?q=word&fields[]=description_with_highlighting"
    description = first_search_result["description_with_highlighting"]

    expect(description).to be_starts_with("…")
    expect(description.size < 350).to be_truthy
  end

  it "returns truncated correctly where result in middle of description" do
    commit_document(
      "government_test",
      "link" => "/some-nice-link",
      "description" => ("something " * 200) + " word " + ("something " * 200),
    )

    get "/search?q=word&fields[]=description_with_highlighting"
    description = first_search_result["description_with_highlighting"]

    expect(description).to be_ends_with("…")
    expect(description).to be_starts_with("…")
  end

private

  def first_search_result
    @first_search_result ||= parsed_response["results"].first
  end
end
