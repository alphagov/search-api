require 'test_helper'

class GovukIndex::ExpandedLinksPresenterTest < Minitest::Test
  def test_mainstream_browse_pages
    expanded_links = {
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

    presenter = expanded_links_presenter(expanded_links)

    expected_mainstream_browse_pages = [
      "visas-immigration/eu-eea-commonwealth", "visas-immigration/work-visas"
    ]

    expected_mainstream_browse_page_content_ids = [
      "5f42c670-5b82-4f1f-ab52-0e100428d430", "4ab4764d-d9ce-425f-a8cc-aaba4a38be09"
    ]

    assert_equal presenter.mainstream_browse_pages, expected_mainstream_browse_pages
    assert_equal presenter.mainstream_browse_page_content_ids, expected_mainstream_browse_page_content_ids
  end

  def test_organisations
    expanded_links = {
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

    presenter = expanded_links_presenter(expanded_links)

    expected_organisations = ["uk-visas-and-immigration"]
    expected_organisation_content_ids = ["04148522-b0c1-4137-b687-5f3c3bdd561a"]
    expected_primary_publishing_organisation = ["uk-visas-and-immigration"]

    assert_equal presenter.organisations, expected_organisations
    assert_equal presenter.organisation_content_ids, expected_organisation_content_ids
    assert_equal presenter.primary_publishing_organisation, expected_primary_publishing_organisation
  end

  def test_taxons
    expanded_links = {
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

    presenter = expanded_links_presenter(expanded_links)

    expected_taxonomy_tree = [
      "206b7f3a-49b5-476f-af0f-fd27e2a68473",
      "5a9e6b26-ae64-4129-93ee-968028381e83",
      "13bba81c-b2b1-4b13-a3de-b24748977198"
    ]
    expected_taxons = ["13bba81c-b2b1-4b13-a3de-b24748977198"]

    assert_equal presenter.part_of_taxonomy_tree, expected_taxonomy_tree
    assert_equal presenter.taxons, expected_taxons
  end

  def test_topics
    expanded_links = {
      "topics" => [
          {
            "base_path" => "/topic/benefits-credits/tax-credits",
            "content_id" => "f881f972-6094-4c7d-849c-9143461a9307",
            "locale" => "en",
            "title" => "Tax credits"
          }
      ]
    }

    presenter = expanded_links_presenter(expanded_links)

    expected_specialist_sectors = ["benefits-credits/tax-credits"]
    expected_topic_content_ids = ["f881f972-6094-4c7d-849c-9143461a9307"]

    assert_equal presenter.specialist_sectors, expected_specialist_sectors
    assert_equal presenter.topic_content_ids, expected_topic_content_ids
  end

  def expanded_links_presenter(expanded_links)
    GovukIndex::ExpandedLinksPresenter.new(expanded_links)
  end
end
