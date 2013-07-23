require "test_helper"
require "document"
require "document_series_registry"

class DocumentSeriesRegistryTest < MiniTest::Unit::TestCase
  def setup
    @index = stub("elasticsearch index")
    @document_series_registry = DocumentSeriesRegistry.new(@index)
  end

  def rail_statistics
    Document.new(
      %w(link title),
      {
        link: "/government/organisations/department-for-transport/series/rail-statistics",
        title: "Rail statistics"
      }
    )
  end

  def test_can_fetch_document_series_by_slug
    @index.stubs(:documents_by_format)
      .with("document_series", anything)
      .returns([rail_statistics])
    document_series = @document_series_registry["rail-statistics"]
    assert_equal rail_statistics.link, document_series.link
    assert_equal rail_statistics.title, document_series.title
  end

  def test_only_required_fields_are_requested_from_index
    @index.expects(:documents_by_format)
      .with("document_series", fields: %w{link title})
    document_series = @document_series_registry["rail-statistics"]
  end

  def test_returns_nil_if_document_series_not_found
    @index.stubs(:documents_by_format)
      .with("document_series", anything)
      .returns([rail_statistics])
    document_series = @document_series_registry["bus-statistics"]
    assert_nil document_series
  end

  def test_document_enumerator_is_traversed_only_once
    document_enumerator = stub("enumerator")
    document_enumerator.expects(:to_a).returns([rail_statistics]).once
    @index.stubs(:documents_by_format)
      .with("document_series", anything)
      .returns(document_enumerator)
      .once
    assert @document_series_registry["rail-statistics"]
    assert @document_series_registry["rail-statistics"]
  end

  def test_uses_cache
    # Make sure we're using TimedCache#get; TimedCache is tested elsewhere, so
    # we don't need to worry about cache expiry tests here.
    TimedCache.any_instance.expects(:get).with().returns([rail_statistics])
    assert @document_series_registry["rail-statistics"]
  end
end
