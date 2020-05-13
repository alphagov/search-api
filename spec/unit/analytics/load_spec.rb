require "spec_helper"
require "analytics/load"

RSpec.describe Analytics::Load do
  subject(:loader) { described_class }

  describe "#upload_csv_to_google_analytics" do
    let(:load_service) { instance_double("Analytics::LoadService") }

    let(:csv) do
      <<~CSV
        ga:productSku,ga:productName,ga:productBrand,ga:productCategoryHierarchy,ga:dimension72,ga:dimension73,ga:dimension74,ga:dimension75,ga:dimension76,ga:dimension77,ga:dimension78,ga:dimension79,ga:dimension80,ga:productSku
        587b0635-2911-49e6-af68-3f0ea1b07cc5,/an-example-page,some_publishing_org,,some page title,some_document_type,some_navigation_supertype,,some_user_journey_supertype,"some_org, another_org, yet_another_org",20170620,,
      CSV
    end

    it "takes a CSV-formatted string and calls Analytics::LoadService" do
      allow(Analytics::LoadService).to receive(:new).and_return(load_service)
      allow(load_service).to receive(:delete_previous_uploads)
      allow(load_service).to receive(:upload_csv).with(csv)

      loader.upload_csv_to_google_analytics(csv)
      expect(load_service).to have_received(:upload_csv).with(csv)
      expect(load_service).to have_received(:delete_previous_uploads)
    end
  end
end
