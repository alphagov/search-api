require "spec_helper"

RSpec.describe QueryComponents::Highlight do
  describe "#payload" do
    it "enables highlighting on title" do
      parameters = Search::QueryParameters.new(parsed_query: {}, return_fields: %w[title_with_highlighting])

      payload = described_class.new(parameters).payload

      expect(payload[:fields].keys).to include(:title)
    end

    it "enables highlighting on title with synonyms" do
      parameters = Search::QueryParameters.new(parsed_query: {}, return_fields: %w[title_with_highlighting])

      payload = described_class.new(parameters).payload

      expect(payload[:fields].keys).to include(:"title.synonym")
    end

    it "enables highlighting on description" do
      parameters = Search::QueryParameters.new(parsed_query: {}, return_fields: %w[description_with_highlighting])

      payload = described_class.new(parameters).payload

      expect(payload[:fields].keys).to include(:description)
    end

    it "enables highlighting on description with synonyms" do
      parameters = Search::QueryParameters.new(parsed_query: {}, return_fields: %w[description_with_highlighting])

      payload = described_class.new(parameters).payload

      expect(payload[:fields].keys).to include(:"description.synonym")
    end

    it "does not enable highlighting when not requested" do
      parameters = Search::QueryParameters.new(parsed_query: {}, return_fields: %w[title])

      payload = described_class.new(parameters).payload

      expect(payload).to be_nil
    end
  end
end
