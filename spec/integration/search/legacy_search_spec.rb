require "spec_helper"

RSpec.describe "ElasticsearchAdvancedSearchTest" do
  before do
    @index_name = "govuk_test"

    add_sample_documents
    commit_index("govuk_test")
  end

  def sample_document_attributes
    [
      {
        "title" => "Cheese in my face",
        "description" => "Hummus weevils",
        "format" => "answer",
        "link" => "/an-example-answer",
        "indexable_content" => "I like my badger: he is tasty and delicious",
        "relevant_to_local_government" => true,
        "updated_at" => "2012-01-01",
      },
      {
        "title" => "Useful government information",
        "description" => "Government, government, government. Developers.",
        "format" => "answer",
        "link" => "/another-example-answer",
        "mainstream_browse_pages" => "crime/example",
        "indexable_content" => "Tax, benefits, roads and stuff",
        "relevant_to_local_government" => false,
        "updated_at" => "2012-01-03",
      },
      {
        "title" => "Cheesey government information",
        "description" => "Government, government, government. Developers.",
        "format" => "answer",
        "link" => "/yet-another-example-answer",
        "mainstream_browse_pages" => "crime/example",
        "indexable_content" => "Tax, benefits, roads and stuff, mostly about cheese",
        "relevant_to_local_government" => true,
        "updated_at" => "2012-01-04",
        "organisations" => ["ministry-of-cheese"],
      },
      {
        "title" => "Pork pies",
        "link" => "/pork-pies",
        "relevant_to_local_government" => true,
        "updated_at" => "2012-01-02",
      },
      {
        "title" => "Doc with attachments",
        "link" => "/doc-with-attachments",
        "attachments" => [
          {
            "title" => "Special thing",
            "command_paper_number" => "1234",
          }
        ],
      }
    ]
  end

  def add_sample_documents
    sample_document_attributes.each do |sample_document|
      insert_document("govuk_test", sample_document)
    end
  end

  def expect_result_links(*links)
    order = true
    if links[-1].is_a?(Hash)
      hash = links.pop
      order = hash[:order]
    end
    parsed_links = parsed_response["results"].map { |r| r["link"] }
    if order
      expect(links).to eq(parsed_links)
    else
      expect(links.sort).to eq(parsed_links.sort)
    end
  end

  def expect_result_total(total)
    expect(total).to eq(parsed_response["total"])
  end

  it "should search by keywords" do
    get "/#{@index_name}/advanced_search.json?per_page=1&page=1&keywords=cheese"
    expect(last_response).to be_ok
    expect_result_total 2
    expect_result_links "/an-example-answer"
  end

  it "should search by nested data" do
    get "/#{@index_name}/advanced_search.json?per_page=1&page=1&keywords=#{CGI.escape('Special thing')}"

    expect(last_response).to be_ok
    expect_result_total 1
    expect_result_links "/doc-with-attachments"
  end

  it "should escape lucene characters" do
    ["badger)", "badger\\"].each do |problem|
      get "/#{@index_name}/advanced_search.json?per_page=1&page=1&keywords=#{CGI.escape(problem)}"
      expect(last_response).to be_ok
      expect_result_links "/an-example-answer"
    end
  end

  it "should allow paging through keyword search" do
    get "/#{@index_name}/advanced_search.json?per_page=1&page=2&keywords=cheese"
    expect(last_response).to be_ok
    expect_result_total 2
    expect_result_links "/yet-another-example-answer"
  end

  it "should filter results by a property" do
    get "/#{@index_name}/advanced_search.json?per_page=2&page=1&mainstream_browse_pages=crime/example"
    expect(last_response).to be_ok
    expect_result_total 2
    expect_result_links "/another-example-answer", "/yet-another-example-answer", order: false
  end

  it "should filter results by a nested property" do
    get "/#{@index_name}/advanced_search.json?per_page=2&page=1&attachments.command_paper_number=1234"
    expect(last_response).to be_ok
    expect_result_total 1
    expect_result_links "/doc-with-attachments"
  end

  it "should allow boolean filtering" do
    get "/#{@index_name}/advanced_search.json?per_page=3&page=1&relevant_to_local_government=true"
    expect(last_response).to be_ok
    expect_result_total 3
    expect_result_links "/an-example-answer", "/yet-another-example-answer", "/pork-pies", order: false
  end

  it "should allow date filtering" do
    get "/#{@index_name}/advanced_search.json?per_page=3&page=1&updated_at[before]=2012-01-03"
    expect(last_response).to be_ok
    expect_result_total 3
    expect_result_links "/an-example-answer", "/another-example-answer", "/pork-pies", order: false
  end

  it "should allow combining all filters" do
    # add another doc to make the filter combination need everything to pick
    # the one we want
    more_documents = [
      {
        "title" => "Government cheese",
        "description" => "Government, government, government. cheese.",
        "format" => "answer",
        "link" => "/cheese-example-answer",
        "mainstream_browse_pages" => "crime/example",
        "indexable_content" => "Cheese tax.  Cheese recipies.  Cheese music.",
        "relevant_to_local_government" => true,
        "updated_at" => "2012-01-01",
      }
    ]
    more_documents.each do |sample_document|
      insert_document("govuk_test", sample_document)
    end

    commit_index("govuk_test")

    get "/#{@index_name}/advanced_search.json?per_page=3&page=1&relevant_to_local_government=true&updated_at[after]=2012-01-02&keywords=tax&mainstream_browse_pages=crime/example"

    expect(last_response).to be_ok
    expect_result_total 1
    expect_result_links "/yet-another-example-answer"
  end

  it "should not expand organisations" do
    # The new organisation registry expands organisations from slugs into
    # hashes; for backwards compatibility, we shouldn't do this until it's
    # configured (and until clients can handle either format).
    get "/#{@index_name}/advanced_search.json?per_page=3&page=1&relevant_to_local_government=true&updated_at[after]=2012-01-02&keywords=tax&mainstream_browse_pages=crime/example"

    expect(last_response).to be_ok
    expect_result_total 1
    expect(parsed_response["results"][0]["organisations"]).to eq(["ministry-of-cheese"])
  end

  it "should allow ordering by properties" do
    get "/#{@index_name}/advanced_search.json?per_page=4&page=1&order[updated_at]=desc"
    expect(last_response).to be_ok
    expect_result_total 5
    expect_result_links "/yet-another-example-answer", "/another-example-answer", "/pork-pies", "/an-example-answer"
  end

  it "does not allow page to be super high" do
    get "/#{@index_name}/advanced_search.json?per_page=4&page=500001&order[updated_at]=desc"

    expect(last_response.status).to eq(422)
  end
end
