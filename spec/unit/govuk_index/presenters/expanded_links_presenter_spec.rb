require "spec_helper"

RSpec.describe GovukIndex::ExpandedLinksPresenter do
  it "mainstream browse pages" do
    expanded_links = {
      "mainstream_browse_pages" => [
        {
          "base_path" => "/browse/visas-immigration/eu-eea-commonwealth",
          "content_id" => "5f42c670-5b82-4f1f-ab52-0e100428d430",
          "locale" => "en",
          "title" => "EU, EEA and Commonwealth",
        },
        {
          "base_path" => "/browse/visas-immigration/work-visas",
          "content_id" => "4ab4764d-d9ce-425f-a8cc-aaba4a38be09",
          "locale" => "en",
          "title" => "Work visas",
        },
      ],
    }

    presenter = expanded_links_presenter(expanded_links)

    expected_mainstream_browse_pages = [
      "visas-immigration/eu-eea-commonwealth", "visas-immigration/work-visas"
    ]

    expected_mainstream_browse_page_content_ids = %w[
      5f42c670-5b82-4f1f-ab52-0e100428d430 4ab4764d-d9ce-425f-a8cc-aaba4a38be09
    ]

    expect(presenter.mainstream_browse_pages).to eq(expected_mainstream_browse_pages)
    expect(presenter.mainstream_browse_page_content_ids).to eq(expected_mainstream_browse_page_content_ids)
  end

  it "organisations" do
    expanded_links = {
      "organisations" => [
        {
          "base_path" => "/government/organisations/uk-visas-and-immigration",
          "content_id" => "04148522-b0c1-4137-b687-5f3c3bdd561a",
          "locale" => "en",
          "title" => "UK Visas and Immigration",
        },
      ],
      "primary_publishing_organisation" => [
        {
          "base_path" => "/government/organisations/uk-visas-and-immigration",
          "content_id" => "04148522-b0c1-4137-b687-5f3c3bdd561a",
          "locale" => "en",
          "title" => "UK Visas and Immigration",
        },
      ],
    }

    presenter = expanded_links_presenter(expanded_links)

    expected_organisations = %w[uk-visas-and-immigration]
    expected_organisation_content_ids = %w[04148522-b0c1-4137-b687-5f3c3bdd561a]
    expected_primary_publishing_organisation = %w[uk-visas-and-immigration]

    expect(presenter.organisations).to eq(expected_organisations)
    expect(presenter.organisation_content_ids).to eq(expected_organisation_content_ids)
    expect(presenter.primary_publishing_organisation).to eq(expected_primary_publishing_organisation)
  end

  it "topical_events" do
    expanded_links = {
      "topical_events" => [
        {
          "base_path" => "/government/topical-events/budget",
          "content_id" => "ca2326a6-b6c4-4750-917f-9fe12d0c59c9",
          "locale" => "en",
          "title" => "The budget",
        },
      ],
    }
    presenter = expanded_links_presenter(expanded_links)

    expected_topical_events = %w[budget]
    expect(presenter.topical_events).to eq(expected_topical_events)
  end

  it "world_locations" do
    expanded_links = {
      "world_locations" => [
        {
          "content_id" => "5e9f420d-7706-11e4-a3cb-005056011aef",
          "title" => "Bonaire/St Eustatius/Saba",
          "schema_name" => "world_location",
          "locale" => "en",
          "analytics_identifier" => "WL224",
          "links" => {},
        },
        {
          "content_id" => "dc258e77-8731-4c7f-9a6f-df508b991298",
          "title" => "Saint-Barthélemy",
          "schema_name" => "world_location",
          "locale" => "en",
          "analytics_identifier" => "WL247",
          "links" => {},
        },
        {
          "content_id" => "5e9f3c6b-7706-11e4-a3cb-005056011aef",
          "title" => "St Helena, Ascension and Tristan da Cunha",
          "schema_name" => "world_location",
          "locale" => "en",
          "analytics_identifier" => "WL216",
          "links" => {},
        },
        {
          "content_id" => "5e9f3c18-7706-11e4-a3cb-005056011aef",
          "title" =>
          "The UK Permanent Delegation to the OECD (Organisation for Economic Co-operation and Development)",
          "schema_name" => "world_location",
          "locale" => "en",
          "analytics_identifier" => "WL210",
          "links" => {},
        },
      ],
    }
    presenter = expanded_links_presenter(expanded_links)

    expected_world_locations = %w[
      bonaire-st-eustatius-saba
      saint-barthelemy
      st-helena-ascension-and-tristan-da-cunha
      the-uk-permanent-delegation-to-the-oecd-organisation-for-economic-co-operation-and-development
    ]

    expect(presenter.world_locations).to eq(expected_world_locations)
  end

  it "taxons" do
    parent_taxons =
      [
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
                "links" => {
                  "root_taxon" => [
                    {
                      "base_path" => "/",
                      "content_id" => "f3bbdec2-0e62-4520-a7fd-6ffd5d36e03a",
                      "locale" => "en",
                      "title" => "GOV.UK homepage",
                      "links" => {},
                    },
                  ],
                },
              },
            ],
          },
        },
      ]

    expanded_links = {
      "taxons" => [
        {
          "base_path" => "/childcare-parenting/adoption",
          "content_id" => "13bba81c-b2b1-4b13-a3de-b24748977198",
          "locale" => "en",
          "title" => "Adoption",
          "links" => {
            "parent_taxons" => parent_taxons,
          },
        },
        {
          "base_path" => "/childcare-parenting/childcare-and-early-years",
          "content_id" => "f1d9c348-5c5e-4fc6-9172-13a62537d3ae",
          "locale" => "en",
          "title" => "Childcare and early years",
          "links" => {
            "parent_taxons" => parent_taxons,
          },
        },
      ],
    }

    presenter = expanded_links_presenter(expanded_links)

    expected_taxonomy_tree = %w[
      f3bbdec2-0e62-4520-a7fd-6ffd5d36e03a
      206b7f3a-49b5-476f-af0f-fd27e2a68473
      5a9e6b26-ae64-4129-93ee-968028381e83
      13bba81c-b2b1-4b13-a3de-b24748977198
      f1d9c348-5c5e-4fc6-9172-13a62537d3ae
    ]
    expected_taxons = %w[
      13bba81c-b2b1-4b13-a3de-b24748977198
      f1d9c348-5c5e-4fc6-9172-13a62537d3ae
    ]

    expect(presenter.part_of_taxonomy_tree).to eq(expected_taxonomy_tree)
    expect(presenter.taxons).to eq(expected_taxons)
  end

  it "facet_values" do
    expanded_links = {
      "facet_values" => [
        { "content_id" => "ec58ec61-71a6-475a-8df5-da5f866990b5" },
        { "content_id" => "dd71726f-3fe5-4e5f-8d29-8f668e32a659" },
      ],
    }

    presenter = expanded_links_presenter(expanded_links)
    expected_facet_values = %w[ec58ec61-71a6-475a-8df5-da5f866990b5 dd71726f-3fe5-4e5f-8d29-8f668e32a659]

    expect(presenter.facet_values).to eq(expected_facet_values)
  end

  it "facet_groups" do
    expanded_links = {
      "facet_groups" => [
        { "content_id" => "ec58ec61-71a6-475a-8df5-da5f866990b5" },
        { "content_id" => "dd71726f-3fe5-4e5f-8d29-8f668e32a659" },
      ],
    }

    presenter = expanded_links_presenter(expanded_links)
    expected_facet_groups = %w[ec58ec61-71a6-475a-8df5-da5f866990b5 dd71726f-3fe5-4e5f-8d29-8f668e32a659]

    expect(presenter.facet_groups).to eq(expected_facet_groups)
  end

  it "topics" do
    expanded_links = {
      "topics" => [
        {
          "base_path" => "/topic/benefits-credits/tax-credits",
          "content_id" => "f881f972-6094-4c7d-849c-9143461a9307",
          "locale" => "en",
          "title" => "Tax credits",
        },
      ],
    }

    presenter = expanded_links_presenter(expanded_links)

    expected_specialist_sectors = ["benefits-credits/tax-credits"]
    expected_topic_content_ids = %w[f881f972-6094-4c7d-849c-9143461a9307]

    expect(presenter.specialist_sectors).to eq(expected_specialist_sectors)
    expect(presenter.topic_content_ids).to eq(expected_topic_content_ids)
  end

  it "people" do
    expanded_links = {
      "people" => [
        {
          "base_path" => "/government/people/badger-of-deploy",
          "content_id" => "dbce902f-36d1-471e-a79a-8934aee7c34c",
          "locale" => "en",
          "title" => "Badger of Deploy",
        },
      ],
    }

    presenter = expanded_links_presenter(expanded_links)

    expect(presenter.people).to eq(%w[badger-of-deploy])
  end

  it "policy groups" do
    expanded_links = {
      "working_groups" => [
        {
          "base_path" => "/government/groups/micropig-advisory-group",
          "content_id" => "33848853-6411-4e36-b72b-afe50aff1b93",
          "locale" => "en",
          "title" => "Micropig advisory group",
        },
      ],
    }

    presenter = expanded_links_presenter(expanded_links)

    expect(presenter.policy_groups).to eq(%w[micropig-advisory-group])
  end

  describe "role_appointments" do
    let(:expanded_links) do
      {
        "role_appointments" => [
          {
            "content_id" => "215f612f-6491-4241-9d91-dd39d1759792",
            "locale" => "en",
            "title" => "Prime Minister",
          },
        ],
      }
    end

    subject(:presenter) { expanded_links_presenter(expanded_links) }

    specify { expect(presenter.role_appointments).to eq(%w[215f612f-6491-4241-9d91-dd39d1759792]) }
  end

  describe "roles" do
    let(:expanded_links) do
      {
        "roles" => [
          {
            "base_path" => "/government/ministers/badger-of-deploy",
            "content_id" => "215f612f-6491-4241-9d91-dd39d1759792",
            "locale" => "en",
            "title" => "Prime Minister",
          },
        ],
      }
    end

    subject(:presenter) { expanded_links_presenter(expanded_links) }

    specify { expect(presenter.roles).to eq(%w[badger-of-deploy]) }
  end

  it "default_news_image" do
    default_news_image_url = "https://www.test.gov.uk/default_news_image.jpg"
    expanded_links = {
      "primary_publishing_organisation" => [
        {
          "details" => {
            "default_news_image" => { "url" => default_news_image_url },
          },
        },
      ],
    }

    presenter = expanded_links_presenter(expanded_links)

    expect(presenter.default_news_image).to eq(default_news_image_url)
  end

  def expanded_links_presenter(expanded_links)
    described_class.new(expanded_links)
  end
end
