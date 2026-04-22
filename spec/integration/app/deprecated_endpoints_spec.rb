require "spec_helper"

RSpec.describe "ContentEndpointsTest" do
  before do
    allow(GovukError).to receive(:notify)
  end
  it "returns an error" do
    post "/govuk_test/documents"
    expect(last_response.status).to eq 403
    expect(GovukError).to have_received(:notify)
  end
end
