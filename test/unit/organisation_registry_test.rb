require "test_helper"
require "document"
require "registry"

class OrganisationRegistryTest < MiniTest::Unit::TestCase
  def setup
    @index = stub("elasticsearch index")
    @organisation_registry = Registry::Organisation.new(@index)
  end

  def mod_document
    Document.new(
      %w(slug link title acronym organisation_type organisation_state),
      {
        link: "/government/organisations/ministry-of-defence",
        slug: "ministry-of-defence",
        title: "Ministry of Defence"
      }
    )
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
      %w(slug link title acronym organisation_type),
      {
        slug: "office-of-the-fonz",
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
      %w(slug link title acronym organisation_type),
      {
        slug: "ministry-of-defence",
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
      %w(slug link title),
      {
        slug: "ministry-of-justice",
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
end
