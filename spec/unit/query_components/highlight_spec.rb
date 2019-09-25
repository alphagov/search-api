require "spec_helper"

RSpec.describe QueryComponents::Highlight do
  describe "#payload" do
    it "enables highlighting on title" do
      parameters = Search::QueryParameters.new(return_fields: %w[title_with_highlighting])

      payload = QueryComponents::Highlight.new(parameters).payload

      expect(payload[:fields].keys).to include(:title)
    end

    it "enables highlighting on title with synonyms" do
      parameters = Search::QueryParameters.new(return_fields: %w[title_with_highlighting])

      payload = QueryComponents::Highlight.new(parameters).payload

      expect(payload[:fields].keys).to include(:"title.synonym")
    end

    it "enables highlighting on description" do
      parameters = Search::QueryParameters.new(return_fields: %w[description_with_highlighting])

      payload = QueryComponents::Highlight.new(parameters).payload

      expect(payload[:fields].keys).to include(:description)
    end

    it "enables highlighting on description with synonyms" do
      parameters = Search::QueryParameters.new(return_fields: %w[description_with_highlighting])

      payload = QueryComponents::Highlight.new(parameters).payload

      expect(payload[:fields].keys).to include(:"description.synonym")
    end

    it "does not enable highlighting when not requested" do
      parameters = Search::QueryParameters.new(return_fields: %w[title])

      payload = QueryComponents::Highlight.new(parameters).payload

      expect(payload).to be_nil
    end
  end
end
