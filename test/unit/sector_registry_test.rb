require "test_helper"
require "document"
require "specialist_sector_registry"

class SectorRegistryTest < MiniTest::Unit::TestCase
  def setup
    @index = stub("elasticsearch index")
    @specialist_sector_registry = SpecialistSectorRegistry.new(@index)
  end

  def oil_and_gas
    Document.new(
      %w(slug link title),
      {
        slug: "oil-and-gas/licensing",
        link: "/oil-and-gas/licensing",
        title: "Licensing"
      }
    )
  end

  def test_can_fetch_sector_by_slug
    @index.stubs(:documents_by_format)
      .with("specialist_sector", anything)
      .returns([oil_and_gas])
    sector = @specialist_sector_registry["oil-and-gas/licensing"]
    assert_equal oil_and_gas.slug, sector.slug
    assert_equal oil_and_gas.link, sector.link
    assert_equal oil_and_gas.title, sector.title
  end

  def test_only_required_fields_are_requested_from_index
    @index.expects(:documents_by_format)
      .with("specialist_sector", fields: %w{slug link title})
    @specialist_sector_registry["oil-and-gas/licensing"]
  end

  def test_returns_nil_if_sector_not_found
    @index.stubs(:documents_by_format)
      .with("specialist_sector", anything)
      .returns([oil_and_gas])
    sector = @specialist_sector_registry["foo"]
    assert_nil sector
  end

  def test_document_enumerator_is_traversed_only_once
    document_enumerator = stub("enumerator")
    document_enumerator.expects(:to_a).returns([oil_and_gas]).once
    @index.stubs(:documents_by_format)
      .with("specialist_sector", anything)
      .returns(document_enumerator)
      .once
    assert @specialist_sector_registry["oil-and-gas/licensing"]
  end

  def test_uses_cache
    # Make sure we're using TimedCache#get; TimedCache is tested elsewhere, so
    # we don't need to worry about cache expiry tests here.
    TimedCache.any_instance.expects(:get).returns([oil_and_gas])
    assert @specialist_sector_registry["oil-and-gas/licensing"]
  end
end
