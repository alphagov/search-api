require "spec_helper"

RSpec.describe "QuotedAndUnquotedSearchTest" do
  before do
    # `@@registries` are set in Rummager and is *not* reset between tests. To
    # prevent caching issues we manually clear them here to make a "new" app.
    Rummager.class_variable_set(:'@@registries', nil)
  end

  it "old weighting three matches found for london" do
    commit_london_transport_docs
    get "/search?q=london"
    expect(last_response.status).to eq(200)
    expect(parsed_response["results"].size).to eq(3)
  end

  it "old weighting three matches found for transport" do
    commit_london_transport_docs
    get "/search?q=transport"
    expect(last_response.status).to eq(200)
    expect(parsed_response["results"].size).to eq(3)
  end

  it "old weighting three matches found for unquoted london transport" do
    commit_london_transport_docs
    get "/search?q=london+transport"
    expect(last_response.status).to eq(200)
    expect(parsed_response["results"].size).to eq(3)
  end

  it "old weighting one match found for quoted london transport" do
    commit_london_transport_docs
    get "/search?q=%22london+transport%22"
    expect(last_response.status).to eq(200)
    expect(parsed_response["results"].size).to eq(1)
  end

  it "old weighting synonyms are returned with unquoted phrases" do
    commit_synonym_documents
    get "/search?q=driving+abroad"
    expect(last_response.status).to eq(200)
    expect(parsed_response["results"].size).to eq(2)
  end

  it "old weighting stemming is in place for unquoted phrases" do
    commit_stemming_documents
    get "/search?q=dog"
    expect(last_response.status).to eq(200)
    expect(parsed_response["results"].size).to eq(2)
  end

  it "old weighting stemming is still in place even for quoted phrases" do
    commit_stemming_documents
    get "/search?q=%22dog%22"
    expect(last_response.status).to eq(200)
    expect(parsed_response["results"].size).to eq(2)
  end

private

  def commit_london_transport_docs
    commit_document(
      "government_test",
      {
        "title" => "This is about London and its environs",
        "indexable_content" => "London is a world-class city with a modern transport infrastucture",
        "link" => "/london-and-environs",
      },
    )

    commit_document(
      "government_test",
      {
        "title" => "This is about the transport in Britain",
        "indexable_content" => "Britain has a developed transport infrastructure, especially in London",
        "link" => "/transport-in-britain",
      },
    )

    commit_document(
      "government_test",
      {
        "title" => "Transport for London formerly known as London Transport",
        "indexable_content" => "Transport for London used to be known as London Transport",
        "link" => "/transport-for-london",
      },
    )
  end

  def commit_synonym_documents
    commit_document(
      "government_test",
      {
        "title" => "Driving abroad",
        "indexable_content" => "Driving abroad can be tricky.  For a start, they drive on the wrong side of the road",
        "link" => "/driving-abroad",
      },
    )

    commit_document(
      "government_test",
      {
        "title" => "Driving overseas",
        "indexable_content" => "Driving overseas can be tricky.  For a start, they drive on the wrong side of the road",
        "link" => "/driving-overseas",
      },
    )
  end

  def commit_stemming_documents
    commit_document(
      "government_test",
      {
        "title" => "Dog ownership",
        "indexable_content" => "Owning a dog is a lifelong commitment",
        "link" => "/dog-ownership",
      },
    )

    commit_document(
      "government_test",
      {
        "title" => "Problem Dogs",
        "indexable_content" => "Dogs which attack people can be put down and the owner prosecuted",
        "link" => "/problem_dogs",
      },
    )
  end
end
