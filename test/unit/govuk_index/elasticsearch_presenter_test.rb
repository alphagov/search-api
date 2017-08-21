require 'test_helper'

class GovukIndex::ElasticsearchPresenterTest < Minitest::Test
  def setup
    super

    @popularity_lookup = stub(:popularity_lookup)
    Indexer::PopularityLookup.stubs(:new).returns(@popularity_lookup)
    @popularity_lookup.stubs(:lookup_popularities).returns({})
  end

  def test_identifier
    payload = generate_random_example(payload: { payload_version: 1 })

    expected_identifier = {
      _type: payload["document_type"],
      _id: payload["base_path"],
      version: 1,
      version_type: "external"
    }

    presenter = elasticsearch_presenter(payload, "help_page")

    assert_equal expected_identifier, presenter.identifier
  end

  def test_common_fields
    defined_fields = {
      base_path: "/some/path",
      details: { body: "We love cheese" },
      expanded_links: {},
    }

    payload = generate_random_example(
      payload: defined_fields,
      excluded_fields: ["withdrawn_notice"]
    )

    presenter = elasticsearch_presenter(payload, "help_page")

    expected_document = {
      content_id: payload["content_id"],
      content_store_document_type: payload["document_type"],
      description: payload["description"],
      email_document_supertype: payload["email_document_supertype"],
      format: payload["document_type"],
      government_document_supertype: payload["government_document_supertype"],
      indexable_content: "\nWe love cheese\n",
      is_withdrawn: false,
      link: "/some/path",
      mainstream_browse_pages: [],
      mainstream_browse_page_content_ids: [],
      navigation_document_supertype: payload["navigation_document_supertype"],
      organisations: [],
      organisation_content_ids: [],
      part_of_taxonomy_tree: [],
      primary_publishing_organisation: [],
      popularity: nil,
      public_timestamp: payload["public_updated_at"],
      publishing_app: payload["publishing_app"],
      rendering_app: payload["rendering_app"],
      specialist_sectors: [],
      taxons: [],
      topic_content_ids: [],
      title: payload["title"],
      user_journey_document_supertype: payload["user_journey_document_supertype"],
    }

    assert_equal expected_document, presenter.document
  end

  def test_mainstream_browse_pages
    expanded_links = {
      "expanded_links" => {
        "mainstream_browse_pages" => [
           {
              "base_path" => "/browse/visas-immigration/eu-eea-commonwealth",
              "content_id" => "5f42c670-5b82-4f1f-ab52-0e100428d430",
              "locale" => "en",
              "title" => "EU, EEA and Commonwealth"
           },
           {
              "base_path" => "/browse/visas-immigration/work-visas",
              "content_id" => "4ab4764d-d9ce-425f-a8cc-aaba4a38be09",
              "locale" => "en",
              "title" => "Work visas"
          }
        ]
      }
    }

    payload = generate_random_example(payload: expanded_links)

    presenter = elasticsearch_presenter(payload, "help_page")

    expected_mainstream_browse_pages = [
      "visas-immigration/eu-eea-commonwealth", "visas-immigration/work-visas"
    ]

    expected_mainstream_browse_page_content_ids = [
      "5f42c670-5b82-4f1f-ab52-0e100428d430", "4ab4764d-d9ce-425f-a8cc-aaba4a38be09"
    ]

    assert_equal presenter.document[:mainstream_browse_pages], expected_mainstream_browse_pages
    assert_equal presenter.document[:mainstream_browse_page_content_ids], expected_mainstream_browse_page_content_ids
  end

  def test_organisations
    expanded_links = {
      "expanded_links" => {
        "organisations" => [
          {
             "base_path" => "/government/organisations/uk-visas-and-immigration",
             "content_id" => "04148522-b0c1-4137-b687-5f3c3bdd561a",
             "locale" => "en",
             "title" => "UK Visas and Immigration"
          },
        ],
        "primary_publishing_organisation" => [
          {
            "base_path" => "/government/organisations/uk-visas-and-immigration",
            "content_id" => "04148522-b0c1-4137-b687-5f3c3bdd561a",
            "locale" => "en",
            "title" => "UK Visas and Immigration"
          }
        ]
      }
    }

    payload = generate_random_example(payload: expanded_links)

    presenter = elasticsearch_presenter(payload, "help_page")

    expected_organisations = ["uk-visas-and-immigration"]
    expected_organisation_content_ids = ["04148522-b0c1-4137-b687-5f3c3bdd561a"]
    expected_primary_publishing_organisation = ["uk-visas-and-immigration"]

    assert_equal presenter.document[:organisations], expected_organisations
    assert_equal presenter.document[:organisation_content_ids], expected_organisation_content_ids
    assert_equal presenter.document[:primary_publishing_organisation], expected_primary_publishing_organisation
  end

  def test_taxons
    expanded_links = {
      "expanded_links" => {
        "taxons" => [
          {
            "base_path" => "/childcare-parenting/adoption",
            "content_id" => "13bba81c-b2b1-4b13-a3de-b24748977198",
            "locale" => "en",
            "title" => "Adoption",
            "links" => {
              "parent_taxons" => [
                {
                  "base_path" => "/childcare-parenting/adoption-fostering-and-surrogacy",
                  "content_id" => "5a9e6b26-ae64-4129-93ee-968028381e83",
                  "locale" => "en",
                  "title" => "Adoption, fostering and surrogacy",
                  "links" => {
                    "parent_taxons" => [
                      {
                        "base_path" => "/childcare-parenting",
                        "content_id" => "206b7f3a-49b5-476f-af0f-fd27e2a68473",
                        "locale" => "en",
                        "title" => "Parenting, childcare and children's services ",
                        "links" => {}
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }

    payload = generate_random_example(payload: expanded_links)

    presenter = elasticsearch_presenter(payload, "help_page")

    expected_taxonomy_tree = [
      "206b7f3a-49b5-476f-af0f-fd27e2a68473",
      "5a9e6b26-ae64-4129-93ee-968028381e83",
      "13bba81c-b2b1-4b13-a3de-b24748977198"
    ]
    expected_taxons = ["13bba81c-b2b1-4b13-a3de-b24748977198"]

    assert_equal presenter.document[:part_of_taxonomy_tree], expected_taxonomy_tree
    assert_equal presenter.document[:taxons], expected_taxons
  end

  def test_topics
    expanded_links = {
      "expanded_links" => {
        "topics" => [
           {
              "base_path" => "/topic/benefits-credits/tax-credits",
              "content_id" => "f881f972-6094-4c7d-849c-9143461a9307",
              "locale" => "en",
              "title" => "Tax credits"
           }
        ]
      }
    }

    payload = generate_random_example(payload: expanded_links)

    presenter = elasticsearch_presenter(payload, "help_page")

    expected_specialist_sectors = ["benefits-credits/tax-credits"]
    expected_topic_content_ids = ["f881f972-6094-4c7d-849c-9143461a9307"]

    assert_equal presenter.document[:specialist_sectors], expected_specialist_sectors
    assert_equal presenter.document[:topic_content_ids], expected_topic_content_ids
  end

  def test_withdrawn_when_withdrawn_notice_present
    payload = {
      "base_path" => "/some/path",
      "withdrawn_notice" => {
        "explanation" => "<div class=\"govspeak\"><p>test 2</p>\n</div>",
        "withdrawn_at" => "2017-08-03T14:02:18Z"
      }
    }

    presenter = elasticsearch_presenter(payload)

    assert_equal presenter.document[:is_withdrawn], true
  end

  def test_popularity_when_value_is_returned_from_lookup
    payload = { "base_path" => "/some/path" }

    popularity = 0.0125356

    Indexer::PopularityLookup.expects(:new).with('govuk_index', SearchConfig.instance).returns(@popularity_lookup)
    @popularity_lookup.expects(:lookup_popularities).with([payload['base_path']]).returns(payload["base_path"] => popularity)

    presenter = elasticsearch_presenter(payload)

    assert_equal popularity, presenter.document[:popularity]
  end

  def test_no_popularity_when_no_value_is_returned_from_lookup
    payload = { "base_path" => "/some/path" }

    Indexer::PopularityLookup.expects(:new).with('govuk_index', SearchConfig.instance).returns(@popularity_lookup)
    @popularity_lookup.expects(:lookup_popularities).with([payload['base_path']]).returns({})

    presenter = elasticsearch_presenter(payload)

    assert_equal nil, presenter.document['popularity']
  end

  def elasticsearch_presenter(payload, type = "aaib_report")
    GovukIndex::ElasticsearchPresenter.new(
      payload: payload,
      type: type,
      sanitiser: GovukIndex::IndexableContentSanitiser.new
    )
  end
end
