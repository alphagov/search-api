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
      %w(link title acronym organisation_type),
      {
        link: "/government/organisations/ministry-of-defence",
        title: "Ministry of Defence"
      }
    )
  end

  def test_uses_Time_as_default_clock
    # This is to make sure the cache expiry is expressed in seconds; DateTime,
    # for example, treats number addition as a number of days.
    TimedCache.expects(:new).with(is_a(Fixnum), Time)
    OrganisationRegistry.new(stub("index"))
  end

  def test_can_fetch_all_organisations
    @index.stubs(:documents_by_format)
      .with("organisation", anything)
      .returns([mod_document])
    assert_equal ["Ministry of Defence"], @organisation_registry.all.map(&:title)
  end

  def test_can_fetch_organisation_by_slug
    @index.stubs(:documents_by_format)
      .with("organisation", anything)
      .returns([mod_document])
    organisation = @organisation_registry["ministry-of-defence"]
    assert_equal "/government/organisations/ministry-of-defence", organisation.link
    assert_equal "Ministry of Defence", organisation.title
  end

  def test_only_required_fields_are_requested_from_index
    @index.expects(:documents_by_format)
      .with("organisation", fields: %w{link title acronym organisation_type})
      .returns([])
    organisation = @organisation_registry["ministry-of-defence"]
  end

  def test_returns_nil_if_organisation_not_found
    @index.stubs(:documents_by_format)
      .with("organisation", anything)
      .returns([mod_document])
    organisation = @organisation_registry["ministry-of-silly-walks"]
    assert_nil organisation
  end

  def test_indicates_organisation_type_from_file
    @index.stubs(:documents_by_format)
      .with("organisation", anything)
      .returns([mod_document])
    organisation = @organisation_registry["ministry-of-defence"]
    assert_equal "Ministerial department", organisation.organisation_type
  end

  def test_indicates_organisation_type_from_index
    fully_labelled_document = Document.new(
      %w(link title acronym organisation_type),
      {
        link: "/government/organisations/office-of-the-fonz",
        title: "Office of The Fonz",
        organisation_type: "Gang"
      }
    )
    @index.stubs(:documents_by_format)
      .with("organisation", anything)
      .returns([fully_labelled_document])
    organisation = @organisation_registry["office-of-the-fonz"]
    assert_equal "Gang", organisation.organisation_type
  end

  def test_organisation_type_from_index_takes_precedence
    fully_labelled_document = Document.new(
      %w(link title acronym organisation_type),
      {
        link: "/government/organisations/ministry-of-defence",
        title: "Ministry of Defence",
        organisation_type: "Stuff and things"
      }
    )
    @index.stubs(:documents_by_format)
      .with("organisation", anything)
      .returns([fully_labelled_document])
    organisation = @organisation_registry["ministry-of-defence"]
    assert_equal "Stuff and things", organisation.organisation_type
  end

  def test_extracts_acronym_from_title_if_missing
    document = Document.new(
      %w(link title acronym),
      {
        link: "/government/organisations/ministry-of-defence",
        title: "Ministry of Defence (MoD)"
      }
    )
    @index.stubs(:documents_by_format)
      .with("organisation", anything)
      .returns([document])
    organisation = @organisation_registry["ministry-of-defence"]
    assert_equal "Ministry of Defence", organisation.title
    assert_equal "MoD", organisation.acronym
  end

  def test_leaves_title_unchanged_if_acronym_present
    document = Document.new(
      %w(link title acronym),
      {
        link: "/government/organisations/ministry-of-defence",
        title: "Ministry of Defence",
        acronym: "MoD"
      }
    )
    @index.stubs(:documents_by_format)
      .with("organisation", anything)
      .returns([document])
    organisation = @organisation_registry["ministry-of-defence"]
    assert_equal "Ministry of Defence", organisation.title
    assert_equal "MoD", organisation.acronym
  end

  def test_leaves_extra_brackets_when_extracting_acronym
    document = Document.new(
      %w(link title acronym),
      {
        link: "/government/organisations/forest-enterprise-england",
        title: "Forest Enterprise (England) (FEE)",
      }
    )
    @index.stubs(:documents_by_format)
      .with("organisation", anything)
      .returns([document])
    organisation = @organisation_registry["forest-enterprise-england"]
    assert_equal "Forest Enterprise (England)", organisation.title
    assert_equal "FEE", organisation.acronym
  end

  def test_leaves_extra_brackets_when_acronym_present
    document = Document.new(
      %w(link title acronym),
      {
        link: "/government/organisations/forest-enterprise-england",
        title: "Forest Enterprise (England)",
        acronym: "FEE"
      }
    )
    @index.stubs(:documents_by_format)
      .with("organisation", anything)
      .returns([document])
    organisation = @organisation_registry["forest-enterprise-england"]
    assert_equal "Forest Enterprise (England)", organisation.title
    assert_equal "FEE", organisation.acronym
  end

  def test_document_enumerator_is_traversed_only_once
    document_enumerator = stub("enumerator")
    document_enumerator.expects(:map).returns([mod_document]).once
    @index.stubs(:documents_by_format)
      .with("organisation", anything)
      .returns(document_enumerator)
      .once
    assert @organisation_registry["ministry-of-defence"]
    assert @organisation_registry["ministry-of-defence"]
  end

  def test_handles_documents_without_acronym_support
    # Until the acronym field is included in the mappings, organisations won't
    # know about the field and will raise an error on #acronym calls.

    document = Document.new(
      %w(link title),
      {
        link: "/government/organisations/ministry-of-justice",
        title: "Ministry of Justice (MoJ)",
      }
    )
    @index.stubs(:documents_by_format)
      .with("organisation", anything)
      .returns([document])
    organisation = @organisation_registry["ministry-of-justice"]
    assert_equal "Ministry of Justice (MoJ)", organisation.title
    assert_raises(NoMethodError) { organisation.acronym }
  end

  def test_uses_cache
    # Make sure we're using TimedCache#get; TimedCache is tested elsewhere, so
    # we don't need to worry about cache expiry tests here.
    TimedCache.any_instance.expects(:get).with().returns([mod_document])
    assert @organisation_registry["ministry-of-defence"]
  end
end
