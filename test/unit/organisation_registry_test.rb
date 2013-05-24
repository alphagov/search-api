require "test_helper"
require "document"
require "organisation_registry"

class OrganisationRegistryTest < MiniTest::Unit::TestCase
  def setup
    @index = stub("elasticsearch index")
    @organisation_registry = OrganisationRegistry.new(@index)
  end

  def mod_document
    Document.new(
      %w(link title),
      {
        link: "/government/organisations/ministry-of-defence",
        title: "Ministry of Defence (MoD)"
      }
    )
  end

  def test_uses_Time_as_default_clock
    # This is to make sure the cache expiry is expressed in seconds; DateTime,
    # for example, treats number addition as a number of days.
    TimedCache.expects(:new).with(is_a(Fixnum), Time)
    OrganisationRegistry.new(stub("index"))
  end

  def test_can_fetch_organisation_by_slug
    @index.stubs(:documents_by_format)
      .with("organisation", anything)
      .returns([mod_document])
    organisation = @organisation_registry["ministry-of-defence"]
    assert_equal "/government/organisations/ministry-of-defence", organisation.link
    assert_equal "Ministry of Defence (MoD)", organisation.title
  end

  def test_only_required_fields_are_requested_from_index
    @index.expects(:documents_by_format)
      .with("organisation", fields: %w{link title})
    organisation = @organisation_registry["ministry-of-defence"]
  end

  def test_returns_nil_if_organisation_not_found
    @index.stubs(:documents_by_format)
      .with("organisation", anything)
      .returns([mod_document])
    organisation = @organisation_registry["ministry-of-silly-walks"]
    assert_nil organisation
  end

  def test_document_enumerator_is_traversed_only_once
    document_enumerator = stub("enumerator")
    document_enumerator.expects(:to_a).returns([mod_document]).once
    @index.stubs(:documents_by_format)
      .with("organisation", anything)
      .returns(document_enumerator)
      .once
    assert @organisation_registry["ministry-of-defence"]
    assert @organisation_registry["ministry-of-defence"]
  end

  def test_uses_cache
    # Make sure we're using TimedCache#get; TimedCache is tested elsewhere, so
    # we don't need to worry about cache expiry tests here.
    TimedCache.any_instance.expects(:get).with().returns([mod_document])
    assert @organisation_registry["ministry-of-defence"]
  end
end
