require "test_helper"
require "document"
require "search/registry"
require "schema/field_definitions"

class SpecialistSectorRegistryTest < MiniTest::Unit::TestCase
  def setup
    @index = stub("elasticsearch index")
    @specialist_sector_registry = Search::BaseRegistry.new(@index, sample_field_definitions, "specialist_sector")
  end

  def oil_and_gas
    {
      "link" => "/topic/oil-and-gas/licensing",
      "slug" => "oil-and-gas/licensing",
      "title" => "Licensing"
    }
  end

  def test_can_fetch_sector_by_slug
    @index.stubs(:documents_by_format)
      .with("specialist_sector", anything)
      .returns([oil_and_gas])
    sector = @specialist_sector_registry["oil-and-gas/licensing"]
    assert_equal oil_and_gas, sector
  end

  def test_only_required_fields_are_requested_from_index
    @index.expects(:documents_by_format)
      .with("specialist_sector", sample_field_definitions(%w{link slug title}))
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

  def test_uses_300_second_cache_lifetime
    Search::TimedCache.expects(:new).with(300, anything)

    Search::BaseRegistry.new(@index, sample_field_definitions, "specialist_sector")
  end
end
