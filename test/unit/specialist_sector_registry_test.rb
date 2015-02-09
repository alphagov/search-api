require "test_helper"
require "document"
require "registry"

class SpecialistSectorRegistryTest < MiniTest::Unit::TestCase
  def setup
    @index = stub("elasticsearch index")
    @specialist_sector_registry = Registry::SpecialistSector.new(@index)
  end

  def oil_and_gas_fields
    {
      "link" => "/oil-and-gas/licensing",
      "title" => "Licensing"
    }
  end

  def oil_and_gas
    Document.new(%w(link title), oil_and_gas_fields)
  end

  def test_can_fetch_sector_by_slug
    @index.stubs(:documents_by_format)
      .with("specialist_sector", anything)
      .returns([oil_and_gas])
    sector = @specialist_sector_registry["oil-and-gas/licensing"]
    assert_equal oil_and_gas.link, sector["link"]
    assert_equal oil_and_gas.title, sector["title"]
  end

  def test_only_required_fields_are_requested_from_index
    @index.expects(:documents_by_format)
      .with("specialist_sector", fields: %w{link title})
      .returns([])
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
    document_enumerator.expects(:map).returns([
      ["oil-and-gas/licensing", oil_and_gas],
    ]).once
    @index.stubs(:documents_by_format)
      .with("specialist_sector", anything)
      .returns(document_enumerator)
      .once
    assert @specialist_sector_registry["oil-and-gas/licensing"]
  end

  def test_uses_cache
    # Make sure we're using TimedCache#get; TimedCache is tested elsewhere, so
    # we don't need to worry about cache expiry tests here.
    TimedCache.any_instance.expects(:get).returns({"oil-and-gas/licensing" => oil_and_gas_fields})
    assert @specialist_sector_registry["oil-and-gas/licensing"]
  end
end
