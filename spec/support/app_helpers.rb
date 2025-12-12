require "spec_helper"

module AppHelpers
  RSpec.shared_examples "govuk index protection" do |path, method: :post|
    let(:error_message) do
      "Actions to govuk index are not allowed via this endpoint, please use the message queue to update this index"
    end

    context "when index_name is govuk" do
      it "halts with 403 and the correct message" do
        send(method, path, {}.to_json)

        expect(last_response.status).to eq(403)
        expect(last_response.body).to eq(error_message)
      end
    end

    context "when index_name is not govuk" do
      it "allows the request to continue" do
        send(method, path.gsub("/govuk/", "/government_test/"), {}.to_json)
        expect(last_response.status).not_to eq(403)
      end
    end
  end
end
