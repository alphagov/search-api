require 'spec_helper'
require 'gds_api/email_alert_api'

RSpec.describe Indexer::MetadataTagger do
  let(:facet_config_file) { File.expand_path("fixtures/facet_config.yml", __dir__) }
  # rubocop:disable RSpec/VerifiedDoubles, RSpec/AnyInstance, RSpec/MessageSpies
  it "amends documents" do
    fixture_file = File.expand_path("fixtures/metadata.csv", __dir__)
    base_path = '/a_base_path'
    test_index_name = 'test-index'

    mock_index = double("index")

    expect_any_instance_of(LegacyClient::IndexForSearch).to receive(:get_document_by_link)
      .and_return('real_index_name' => test_index_name)

    metadata = {
      "sector_business_area" => %w(aerospace agriculture),
      "business_activity" => %w(yes),
      "appear_in_find_eu_exit_guidance_business_finder" => "yes"
    }

    allow(described_class)
      .to receive(:find_all_eu_exit_guidance)
      .and_return(
        {
          results:
            [
              { "link" => "a_base_path", item: "one" },
              { "link" => "another_base_path", item: "two" }
            ]
        }
    )

    expect(mock_index).to receive(:amend).with(base_path, metadata)
    expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with(test_index_name)
      .and_return(mock_index)

    described_class.initialise(fixture_file, facet_config_file)
    described_class.amend_all_metadata
  end

  it "notifies for new documents" do
    fixture_file = File.expand_path("fixtures/metadata.csv", __dir__)
    base_path = '/a_base_path'
    test_index_name = 'test-index'

    mock_index = double("index")
    mock_email_alert_api = double("email_alert_api")

    expect_any_instance_of(LegacyClient::IndexForSearch).to receive(:get_document_by_link)
      .and_return(
        'real_index_name' => test_index_name,
        '_source' => {
          "link" => "/a_base_path",
          "content_id" => "f2b1e88f-fdb3-4338-80c3-c36ac9b385ac",
          "tags" => {}
        }
      )

    expect(GdsApi::EmailAlertApi).to receive(:new).and_return(mock_email_alert_api)

    metadata = {
      "sector_business_area" => %w(aerospace agriculture),
      "business_activity" => %w(yes),
      "appear_in_find_eu_exit_guidance_business_finder" => "yes"
    }

    allow(described_class)
      .to receive(:find_all_eu_exit_guidance)
      .and_return(
        {
          results:
            [
              { "link" => "differnt_base_path", item: "one" },
              { "link" => "another_base_path", item: "two" }
            ]
        }
    )

    expect(mock_index).to receive(:amend).with(base_path, metadata)
    expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with(test_index_name)
      .and_return(mock_index)

    expect(mock_email_alert_api).to receive(:send_alert).with(
      a_hash_including(
        base_path: "/a_base_path",
        content_id: "f2b1e88f-fdb3-4338-80c3-c36ac9b385ac",
        tags: {
          "appear_in_find_eu_exit_guidance_business_finder" => "yes",
          "business_activity" => %W(yes),
          "sector_business_area" => %W(aerospace agriculture),
        },
      )
    )

    described_class.initialise(fixture_file, facet_config_file)
    described_class.amend_all_metadata
  end



  context "when removing metadata" do
    def nil_metadata_hash
      {
        "business_activity" => nil,
        "employ_eu_citizens" => nil,
        "eu_uk_government_funding" => nil,
        "regulations_and_standards" => nil,
        "personal_data" => nil,
        "intellectual_property" => nil,
        "public_sector_procurement" => nil,
        "sector_business_area" => nil,
        "appear_in_find_eu_exit_guidance_business_finder" => nil
      }
    end

    it "nils out all metadata for a base path" do
      fixture_file = File.expand_path("fixtures/metadata.csv", __dir__)
      base_path = "/a_base_path"
      test_index = "test_index"

      mock_index = double("index")

      expect_any_instance_of(LegacyClient::IndexForSearch).to receive(:get_document_by_link)
        .and_return("real_index_name" => test_index)

      expect(mock_index).to receive(:amend).with(base_path, nil_metadata_hash)
      expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
        .with(test_index)
        .and_return(mock_index)

      described_class.initialise(fixture_file, facet_config_file)
      described_class.remove_all_metadata_for_base_paths(base_path)
    end

    it "clears all eu exit guidance metadata" do
      fixture_file = File.expand_path("fixtures/metadata.csv", __dir__)

      allow(described_class)
        .to receive(:find_all_eu_exit_guidance)
        .and_return(
          {
            results:
              [
                { "link" => "a_base_path", item: "one" },
                { "link" => "another_base_path", item: "two" }
              ]
          }
      )

      expect(described_class)
        .to receive(:remove_all_metadata_for_base_paths)
        .with(%w(a_base_path another_base_path))

      described_class.initialise(fixture_file, facet_config_file)
      described_class.destroy_all_eu_exit_guidance!
    end
  end

  describe "email_alert_api_payload" do
    let(:document) {
      {
        "content_id" => "9d58f37a-7ebe-436a-b7fc-bdb5e287a2b3",
        "title" => "Operating in the EU after Brexit",
        "description" => "When the UK leaves the EU, the way businesses both offer services in the EU and operate will change.",
        "publishing_app" => "whitehall",
        "content_store_document_type" => "detailed_guide",
        "public_timestamp" => "2018-01-02 10:10:20.002",
        "link" => "/guidance/operating-in-the-eu-after-brexit",
        "taxons" => { a: 'a', b: 'b' },
        "organisation_content_ids" => ["16f03199-c4f4-408f-844c-bd8489b0a06b"],
      }
    }
    let(:metadata) {
      {
        "sector_business_area" => %w(aerospace agriculture),
        "business_activity" => %w(yes),
        "appear_in_find_eu_exit_guidance_business_finder" => "yes"
      }
    }
    let(:payload) {
      described_class.email_alert_api_payload(document, metadata)
    }

    it "presents metadata as tags" do
      expect(payload[:tags]).to eq(metadata)
    end

    it "presents common document attributes" do
      %i[content_id title description publishing_app].each do |key|
        expect(payload[key]).to eq(document[key.to_s])
      end
    end

    it "presents urgency and priority fields" do
      expect(payload[:urgent]).to be true
      expect(payload[:priority]).to eq("high")
    end

    it "presents fields mapped to appropriate keys" do
      expect(payload[:base_path]).to eq(document["link"])
      expect(payload[:document_type]).to eq(document["content_store_document_type"])
      expect(payload[:public_updated_at]).to eq(document["public_timestamp"])
    end

    it "presents links" do
      links = payload[:links]
      expect(links[:content_id]).to eq(document["content_id"])
      expect(links[:organisations]).to eq(document["organisation_content_ids"])
      expect(links[:taxons]).to eq(document["taxons"])
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles, RSpec/AnyInstance, RSpec/MessageSpies
end
