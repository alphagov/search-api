require "spec_helper"

module AppHelpers
  RSpec.shared_examples "json-only endpoint" do |base_path, query_parameters|
    disallowed_formats = %w[.xml .html .txt .csv]
    def path(base_path:, query_parameters: "", format: "")
      "#{base_path}#{format}#{query_parameters}"
    end
    context "allowed formats" do
      it "allows request with no format" do
        get path(base_path:, query_parameters:)
        expect(last_response.status).not_to eq(404)
      end

      it "allows request with .json format" do
        get path(base_path:, query_parameters:, format: ".json")
        expect(last_response.status).not_to eq(404)
      end
    end

    context "disallowed formats" do
      disallowed_formats.each do |format|
        it "returns 404 for #{format}" do
          get path(base_path:, query_parameters:, format:)

          expect(last_response.status).to eq(404)

          # json_only sets caching for invalid formats
          expect(last_response.headers["Cache-Control"]).to include("public")
          expect(last_response.headers["Cache-Control"]).to include("max-age=86400")
          expect(last_response.headers["Expires"]).not_to be_nil
        end
      end
    end
  end

  RSpec.shared_examples "rejects unknown index" do |path, method: :post|
    it "returns 404 if the index does not exist" do
      send(method, path, {}.to_json)

      expect(last_response.status).to eq(404)
    end
  end

  RSpec.shared_examples "govuk and detailed index protection" do |path, method: :post|
    let(:error_message) do
      "Actions to the govuk or detailed indices are not allowed via this endpoint."
    end

    context "when index_name is govuk" do
      it "halts with 403 and the correct message" do
        send(method, path.gsub(":index", "govuk"), {}.to_json)

        expect(last_response.status).to eq(403)
        expect(last_response.body).to eq(error_message)
      end
    end

    context "when index_name is detailed" do
      it "halts with 403 and the correct message" do
        send(method, path.gsub(":index", "detailed"), {}.to_json)

        expect(last_response.status).to eq(403)
        expect(last_response.body).to eq(error_message)
      end
    end

    context "when index_name is not govuk or detailed" do
      it "allows the request to continue" do
        send(method, path.gsub(":index", "government_test"), {}.to_json)
        expect(last_response.status).not_to eq(403)
      end
    end
  end
end
