require "spec_helper"

RSpec.describe "Deprecate content endpoints" do
  before do
    allow(GovukError).to receive(:notify)
  end

  shared_examples "forbidden request" do |http_method, path|
    it "returns 403 and notifies GovukError for #{http_method.upcase} #{path}" do
      send(http_method, path)

      expect(last_response.status).to eq(403)
      expect(GovukError).to have_received(:notify)
    end
  end

  include_examples "forbidden request", :post, "/govuk_test/documents"
  include_examples "forbidden request", :post, "/govuk_test/documents/link"
  include_examples "forbidden request", :delete, "/govuk_test/documents/link"
  include_examples "forbidden request", :get, "/content"
  include_examples "forbidden request", :delete, "/content"
end
