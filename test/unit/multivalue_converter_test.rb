require "test_helper"
require "legacy_client/multivalue_converter"

class MultivalueConverterTest < MiniTest::Unit::TestCase
  def test_keeps_multivalue_fields_as_array
    fields = {
      "title" => ["the title"],
      "organisations" => %w(hmrc dvla),
    }

    converted_hash = LegacyClient::MultivalueConverter.new(fields, sample_field_definitions).converted_hash

    assert_equal %w(hmrc dvla), converted_hash["organisations"]
  end

  def test_converts_single_value_fields_as_single_value
    fields = {
      "title" => ["the title"],
      "organisations" => %w(hmrc dvla),
    }

    converted_hash = LegacyClient::MultivalueConverter.new(fields, sample_field_definitions).converted_hash

    assert_equal "the title", converted_hash["title"]
  end

  # This might not be necessary since the new ES.
  def test_converts_also_from_single_value_fields
    fields = {
      "title" => "the title",
      "organisations" => %w(hmrc dvla),
    }

    converted_hash = LegacyClient::MultivalueConverter.new(fields, sample_field_definitions).converted_hash

    assert_equal "the title", converted_hash["title"]
  end
end
