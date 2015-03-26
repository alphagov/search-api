require "test_helper"
require "document"
require "registry"
require "schema/field_definitions"
require "sample_config"

class SpecialistSectorRegistryTest < MiniTest::Unit::TestCase
  def setup
    @index = stub("elasticsearch index")
    @specialist_sector_registry = Registry::SpecialistSector.new(@index, sample_field_definitions)
  end

  def oil_and_gas
    Document.new(
      sample_field_definitions(%w{link title}),
      link: "/oil-and-gas/licensing",
      title: "Licensing"
    )
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
      .with("specialist_sector", sample_field_definitions(%w{link title}))
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

  def test_uses_300_second_cache_lifetime
    TimedCache.expects(:new).with(300, anything)

    Registry::SpecialistSector.new(@index, sample_field_definitions)
  end
end
