require "spec_helper"

RSpec.describe LegacyClient::MultivalueConverter do
  it "keeps multivalue fields as array" do
    fields = {
      "title" => ["the title"],
      "organisations" => %w(hmrc dvla),
    }

    converted_hash = described_class.new(fields, sample_field_definitions).converted_hash

    expect(%w(hmrc dvla)).to eq(converted_hash["organisations"])
  end

  it "converts single value fields as single value" do
    fields = {
      "title" => ["the title"],
      "organisations" => %w(hmrc dvla),
    }

    converted_hash = described_class.new(fields, sample_field_definitions).converted_hash

    expect(converted_hash["title"]).to eq("the title")
  end

  # This might not be necessary since the new ES.
  it "converts also from single value fields" do
    fields = {
      "title" => "the title",
      "organisations" => %w(hmrc dvla),
    }

    converted_hash = described_class.new(fields, sample_field_definitions).converted_hash

    expect(converted_hash["title"]).to eq("the title")
  end
end
