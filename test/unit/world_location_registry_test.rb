require "test_helper"
require "document"
require "world_location_registry"

class WorldLocationRegistryTest < MiniTest::Unit::TestCase
  def setup
    @index = stub("elasticsearch index")
    @world_location_registry = WorldLocationRegistry.new(@index)
  end

  def angola
    Document.new(
      %w(slug link title),
      {
        slug: "angola",
        link: "/government/world/angola",
        title: "Angola"
      }
    )
  end

  def test_can_fetch_world_location_by_slug
    @index.stubs(:documents_by_format)
      .with("world_location", anything)
      .returns([angola])
    world_location = @world_location_registry["angola"]
    assert_equal angola.slug, world_location.slug
    assert_equal angola.link, world_location.link
    assert_equal angola.title, world_location.title
  end

  def test_can_fall_back_to_link_munging
    # TODO: remove this functionality once we have everything migrated
    angola_without_slug = Document.new(
      # The document is still aware of slugs
      %w(slug link title),
      {
        link: "/government/world/angola",
        title: "Angola"
      }
    )
    @index.stubs(:documents_by_format)
      .with("world_location", anything)
      .returns([angola_without_slug])
    world_location = @world_location_registry["angola"]
    assert_equal angola.link, world_location.link
    assert_equal angola.title, world_location.title
  end

  def test_only_required_fields_are_requested_from_index
    @index.expects(:documents_by_format)
      .with("world_location", fields: %w{slug link title})
    world_location = @world_location_registry["angola"]
  end

  def test_returns_nil_if_world_location_not_found
    @index.stubs(:documents_by_format)
      .with("world_location", anything)
      .returns([angola])
    world_location = @world_location_registry["mali"]
    assert_nil world_location
  end

  def test_document_enumerator_is_traversed_only_once
    document_enumerator = stub("enumerator")
    document_enumerator.expects(:to_a).returns([angola]).once
    @index.stubs(:documents_by_format)
      .with("world_location", anything)
      .returns(document_enumerator)
      .once
    assert @world_location_registry["angola"]
    assert @world_location_registry["angola"]
  end

  def test_uses_cache
    # Make sure we're using TimedCache#get; TimedCache is tested elsewhere, so
    # we don't need to worry about cache expiry tests here.
    TimedCache.any_instance.expects(:get).with().returns([angola])
    assert @world_location_registry["angola"]
  end
end
