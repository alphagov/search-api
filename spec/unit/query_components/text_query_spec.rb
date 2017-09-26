require 'spec_helper'

RSpec.describe QueryComponents::TextQuery do
  context "search with debug disabling use of synonyms" do
    it "use the all_searchable_text.synonym field" do
      builder = described_class.new(search_query_params)

      query = builder.payload

      assert_match(/all_searchable_text.synonym/, query.to_s)
    end

    it "not use the all_searchable_text.synonym field" do
      builder = described_class.new(search_query_params(debug: { disable_synonyms: true }))

      query = builder.payload

      refute_match(/all_searchable_text.synonym/, query.to_s)
    end
  end

  context "quoted strings" do
    it "call the payload for quoted strings" do
      params = search_query_params(query: %{"all sorts of stuff"})
      builder = described_class.new(params)
      expect(builder).to receive(:payload_for_quoted_phrase).once

      builder.payload
    end
  end

  context "unquoted strings" do
    it "call the payload for unquoted strings" do
      params = search_query_params(query: %{all sorts of stuff})
      builder = described_class.new(params)
      expect(builder).to receive(:payload_for_unquoted_phrase).once

      builder.payload
    end
  end
end
