require 'spec_helper'

RSpec.describe 'BaseRegistryTest' do
  before do
    @index = stub("elasticsearch index")
    @base_registry = Search::BaseRegistry.new(@index, sample_field_definitions, "example-format")
  end

  def example_document
    {
      "content_id" => "example-content-id",
      "slug" => "example-document",
      "link" => "/government/example-document",
      "title" => "Example document"
    }
  end

  it "uses_time_as_default_clock" do
    # This is to make sure the cache expiry is expressed in seconds; DateTime,
    # for example, treats number addition as a number of days.
    Search::TimedCache.expects(:new).with(is_a(Fixnum), Time)
    Search::BaseRegistry.new(@index, sample_field_definitions, "example-format")
  end

  it "can_fetch_document_series_by_slug" do
    @index.stubs(:documents_by_format)
      .with("example-format", anything)
      .returns([example_document])

    fetched_document = @base_registry["example-document"]
    assert_equal example_document, fetched_document
  end

  it "only_required_fields_are_requested_from_index" do
    @index.expects(:documents_by_format)
      .with("example-format", sample_field_definitions(%w{slug link title content_id}))

    @base_registry["example-document"]
  end

  it "returns_nil_if_document_collection_not_found" do
    @index.stubs(:documents_by_format)
      .with("example-format", anything)
      .returns([example_document])
    assert_nil @base_registry["non-existent-document"]
  end

  it "document_enumerator_is_traversed_only_once" do
    document_enumerator = stub("enumerator")
    document_enumerator.expects(:to_a).returns([example_document]).once
    @index.stubs(:documents_by_format)
      .with("example-format", anything)
      .returns(document_enumerator)
      .once
    assert @base_registry["example-document"]
    assert @base_registry["example-document"]
  end

  it "uses_cache" do
    # Make sure we're using TimedCache#get; TimedCache is tested elsewhere, so
    # we don't need to worry about cache expiry tests here.
    Search::TimedCache.any_instance.expects(:get).with.returns([example_document])
    assert @base_registry["example-document"]
  end

  it "find_by_content_id" do
    @index.stubs(:documents_by_format)
      .with("example-format", anything)
      .returns([example_document])

    assert_equal(
      @base_registry.by_content_id("example-content-id"),
      example_document
    )
  end
end
