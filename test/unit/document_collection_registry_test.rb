require "test_helper"
require "document"
require "document_collection_registry"

class DocumentCollectionRegistryTest < MiniTest::Unit::TestCase
  def setup
    @index = stub("elasticsearch index")
    @document_collection_registry = DocumentCollectionRegistry.new(@index)
  end

  def rail_statistics
    Document.new(
      %w(slug link title),
      {
        slug: "rail-statistics",
        link: "/government/collections/rail-statistics",
        title: "Rail statistics"
      }
    )
  end

  def test_can_fetch_document_collection_by_slug
    @index.stubs(:documents_by_format)
      .with("document_collection", anything)
      .returns([rail_statistics])
    document_collection = @document_collection_registry["rail-statistics"]
    assert_equal rail_statistics.slug, document_collection.slug
    assert_equal rail_statistics.link, document_collection.link
    assert_equal rail_statistics.title, document_collection.title
  end

  def test_only_required_fields_are_requested_from_index
    @index.expects(:documents_by_format)
      .with("document_collection", fields: %w{slug link title})
    document_collection = @document_collection_registry["rail-statistics"]
  end

  def test_returns_nil_if_document_collection_not_found
    @index.stubs(:documents_by_format)
      .with("document_collection", anything)
      .returns([rail_statistics])
    document_collection = @document_collection_registry["bus-statistics"]
    assert_nil document_collection
  end

  def test_document_enumerator_is_traversed_only_once
    document_enumerator = stub("enumerator")
    document_enumerator.expects(:to_a).returns([rail_statistics]).once
    @index.stubs(:documents_by_format)
      .with("document_collection", anything)
      .returns(document_enumerator)
      .once
    assert @document_collection_registry["rail-statistics"]
    assert @document_collection_registry["rail-statistics"]
  end

  def test_uses_cache
    # Make sure we're using TimedCache#get; TimedCache is tested elsewhere, so
    # we don't need to worry about cache expiry tests here.
    TimedCache.any_instance.expects(:get).with().returns([rail_statistics])
    assert @document_collection_registry["rail-statistics"]
  end
end
