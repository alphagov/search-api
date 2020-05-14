require "spec_helper"
require "google/apis/analytics_v3"
require "googleauth"
require "analytics/load_service"

RSpec.describe Analytics::LoadService do
  subject(:load_service) { described_class.new }

  let(:service) { Google::Apis::AnalyticsV3::AnalyticsService.new }
  let(:authorizer) { Google::Auth::ServiceAccountCredentials.new }
  let(:csv) do
    <<~CSV
      ga:productSku,ga:productName,ga:productBrand,ga:productCategoryHierarchy,ga:dimension72,ga:dimension73,ga:dimension74,ga:dimension75,ga:dimension76,ga:dimension77,ga:dimension78,ga:dimension79,ga:dimension80,ga:productSku
      587b0635-2911-49e6-af68-3f0ea1b07cc5,/an-example-page,some_publishing_org,,some page title,some_document_type,some_navigation_supertype,,some_user_journey_supertype,"some_org, another_org, yet_another_org",20170620,,
    CSV
  end
  let(:scope) { "https://www.googleapis.com/auth/analytics.edit" }
  let(:upload_response) do
    instance_double(
      "Google::Apis::AnalyticsV3::Upload",
      account_id: "1234",
      custom_data_source_id: "abcdefg",
      id: "AbCd-1234",
      kind: "analytics#upload",
      status: "PENDING",
    )
  end

  let(:uploaded_item) do
    instance_double(
      "Google::Apis::AnalyticsV3::Upload",
      account_id: "1234",
      custom_data_source_id: "abcdefg",
      id: "AbCd-1234",
      kind: "analytics#upload",
      status: "COMPLETED",
    )
  end
  let(:uploaded_item2) do
    instance_double(
      "Google::Apis::AnalyticsV3::Upload",
      account_id: "1234",
      custom_data_source_id: "abcdefg",
      errors: ["Column headers missing for the input file."],
      id: "AbCd-1234",
      kind: "analytics#upload",
      status: "FAILED",
      upload_time: "Thu, 11 Jan 2018 12:36:35 +0000",
    )
  end

  let(:upload_list) do
    instance_double(
      "Google::Apis::AnalyticsV3::Uploads",
      items: [uploaded_item, uploaded_item2],
      items_per_page: 1000,
      kind: "analytics#uploads",
      start_index: 1,
      total_results: 3,
    )
  end

  before do
    ENV["GOOGLE_CLIENT_EMAIL"] = "email@example.org"
    ENV["GOOGLE_PRIVATE_KEY"] = "private_key"
    ENV["GOOGLE_EXPORT_ACCOUNT_ID"] = "account_id"
    ENV["GOOGLE_EXPORT_CUSTOM_DATA_SOURCE_ID"] = "data_source_id"
    ENV["GOOGLE_EXPORT_WEB_PROPERTY_ID"] = "web_property_id"

    allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(authorizer)
  end

  describe "#upload_csv" do
    it "returns a confirmation that the data has been received" do
      allow(load_service.service).to receive(:upload_data).and_return(upload_response)

      expect(load_service.upload_csv(csv)).to eq(upload_response)

      expect(load_service.service).to have_received(:upload_data)
    end

    context "when env vars are unset" do
      before do
        ENV["GOOGLE_CLIENT_EMAIL"] = nil
        ENV["GOOGLE_PRIVATE_KEY"] = nil
        ENV["GOOGLE_EXPORT_ACCOUNT_ID"] = nil
        ENV["GOOGLE_EXPORT_CUSTOM_DATA_IMPORT_SOURCE_ID"] = nil
        ENV["GOOGLE_EXPORT_TRACKER_ID"] = nil
      end

      it "raises an ArgumentError" do
        expect { load_service.upload_csv(csv) }.to raise_error ArgumentError
      end
    end
  end

  describe "#delete_previous_uploads" do
    let(:uploaded_item3) do
      instance_double(
        "Google::Apis::AnalyticsV3::Upload",
        account_id: "1234",
        custom_data_source_id: "abcdefg",
        errors: ["Column headers missing for the input file."],
        id: "AbCd-1234",
        kind: "analytics#upload",
        status: "FAILED",
        upload_time: "Thu, 13 Jan 2018 12:36:35 +0000",
      )
    end

    let(:upload_list2) do
      instance_double(
        "Google::Apis::AnalyticsV3::Uploads",
        items: [uploaded_item, uploaded_item2, uploaded_item3],
        items_per_page: 1000,
        kind: "analytics#uploads",
        start_index: 1,
        total_results: 3,
      )
    end

    before do
      allow(load_service.service).to receive(:list_uploads).and_return(upload_list)
      allow(load_service.service).to receive(:delete_upload_data).and_return("")
    end

    it "deletes the existing files" do
      allow(load_service.service).to receive(:list_uploads).and_return(upload_list)

      load_service.delete_previous_uploads
      expect(load_service.service).to have_received(:list_uploads).with("account_id", "web_property_id", "data_source_id")
    end

    context "when env vars are unset" do
      before do
        ENV["GOOGLE_CLIENT_EMAIL"] = nil
        ENV["GOOGLE_PRIVATE_KEY"] = nil
        ENV["GOOGLE_EXPORT_ACCOUNT_ID"] = nil
        ENV["GOOGLE_EXPORT_CUSTOM_DATA_IMPORT_SOURCE_ID"] = nil
        ENV["GOOGLE_EXPORT_TRACKER_ID"] = nil
      end

      it "raises an ArgumentError" do
        expect { load_service.delete_previous_uploads }.to raise_error ArgumentError
      end
    end
  end
end
