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
end
