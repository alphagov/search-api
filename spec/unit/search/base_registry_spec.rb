require "spec_helper"

RSpec.describe Search::BaseRegistry do
  before do
    @index = double("elasticsearch index")
    @base_registry = described_class.new(@index, sample_field_definitions, "example-format")
  end

  def example_document
    {
      "content_id" => "example-content-id",
      "slug" => "example-document",
      "link" => "/government/example-document",
      "title" => "Example document",
    }
  end

  it "uses time as default clock" do
    # This is to make sure the cache expiry is expressed in seconds; DateTime,
    # for example, treats number addition as a number of days.
    expect(Search::TimedCache).to receive(:new).with(an_instance_of(Integer), Time)
    described_class.new(@index, sample_field_definitions, "example-format")
  end

  it "can fetch document series by slug" do
    allow(@index).to receive(:documents_by_format)
      .with("example-format", anything)
      .and_return([example_document])

    fetched_document = @base_registry["example-document"]
    expect(example_document).to eq(fetched_document)
  end

  it "only required fields are requested from index" do
    expect(@index).to receive(:documents_by_format)
      .with("example-format", sample_field_definitions(%w{slug link title content_id}))

    @base_registry["example-document"]
  end

  it "returns nil if document collection not found" do
    allow(@index).to receive(:documents_by_format)
      .with("example-format", anything)
      .and_return([example_document])
    expect(@base_registry["non-existent-document"]).to be_nil
  end

  it "document enumerator is traversed only once" do
    document_enumerator = double("enumerator")
    expect(document_enumerator).to receive(:to_a).once.and_return([example_document])
    allow(@index).to receive(:documents_by_format)
      .with("example-format", anything)
      .once
      .and_return(document_enumerator)
    expect(@base_registry["example-document"]).to be_truthy
    expect(@base_registry["example-document"]).to be_truthy
  end

  it "uses cache" do
    # Make sure we're using TimedCache#get; TimedCache is tested elsewhere, so
    # we don't need to worry about cache expiry tests here.
    expect_any_instance_of(Search::TimedCache).to receive(:get).with(no_args).and_return([example_document])
    expect(@base_registry["example-document"]).to be_truthy
  end

  it "find by content_id" do
    allow(@index).to receive(:documents_by_format)
      .with("example-format", anything)
      .and_return([example_document])

    expect(
      @base_registry.by_content_id("example-content-id")
    ).to eq(example_document)
  end
end
