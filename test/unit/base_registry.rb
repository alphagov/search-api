require "test_helper"
require "document"
require "registry"

class BaseRegistryTest < MiniTest::Unit::TestCase
  def setup
    @index = stub("elasticsearch index")
    @base_registry = Registry::BaseRegistry.new(@index, "example-format")
  end

  def example_document
    Document.new(
      %w(slug link title),
      {
        slug: "example-document",
        link: "/government/example-document",
        title: "Example document"
      }
    )
  end

  def test_uses_time_as_default_clock
    # This is to make sure the cache expiry is expressed in seconds; DateTime,
    # for example, treats number addition as a number of days.
    TimedCache.expects(:new).with(is_a(Fixnum), Time)
    Registry::BaseRegistry.new(@index, "example-format")
  end

  def test_can_fetch_document_series_by_slug
    @index.stubs(:documents_by_format)
      .with("elasticsearch index", anything)
      .returns([example_document])

    fetched_document = @base_registry["example-document"]
    assert_equal example_document.slug, fetched_document.slug
    assert_equal example_document.link, fetched_document.link
    assert_equal example_document.title, fetched_document.title
  end

  def test_only_required_fields_are_requested_from_index
    @index.expects(:documents_by_format)
      .with("example-format", fields: %w{slug link title})
    fetched_documents = @base_registry["example-document"]
  end

  def test_returns_nil_if_document_collection_not_found
    @index.stubs(:documents_by_format)
      .with("example-format", anything)
      .returns([example_document])
    assert_nil @base_registry["non-existent-document"]
  end

  def test_document_enumerator_is_traversed_only_once
    document_enumerator = stub("enumerator")
    document_enumerator.expects(:to_a).returns([example_document]).once
    @index.stubs(:documents_by_format)
      .with("example_format", anything)
      .returns(document_enumerator)
      .once
    assert @base_registry["example-document"]
    assert @base_registry["example-document"]
  end

  def test_uses_cache
    # Make sure we're using TimedCache#get; TimedCache is tested elsewhere, so
    # we don't need to worry about cache expiry tests here.
    TimedCache.any_instance.expects(:get).with().returns([example_document])
    assert @base_registry["example-document"]
  end
end
