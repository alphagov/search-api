require 'spec_helper'

RSpec.describe 'MultivalueConverterTest' do
  it "keeps_multivalue_fields_as_array" do
    fields = {
      "title" => ["the title"],
      "organisations" => %w(hmrc dvla),
    }

    converted_hash = LegacyClient::MultivalueConverter.new(fields, sample_field_definitions).converted_hash

    assert_equal %w(hmrc dvla), converted_hash["organisations"]
  end

  it "converts_single_value_fields_as_single_value" do
    fields = {
      "title" => ["the title"],
      "organisations" => %w(hmrc dvla),
    }

    converted_hash = LegacyClient::MultivalueConverter.new(fields, sample_field_definitions).converted_hash

    assert_equal "the title", converted_hash["title"]
  end

  # This might not be necessary since the new ES.
  it "converts_also_from_single_value_fields" do
    fields = {
      "title" => "the title",
      "organisations" => %w(hmrc dvla),
    }

    converted_hash = LegacyClient::MultivalueConverter.new(fields, sample_field_definitions).converted_hash

    assert_equal "the title", converted_hash["title"]
  end
end
