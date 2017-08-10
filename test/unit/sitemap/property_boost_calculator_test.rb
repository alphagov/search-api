require "test_helper"
require "sitemap/sitemap"

class PropertyBoostCalculatorTest < Minitest::Test
  def test_boosts_are_between_0_and_1
    stub_boost_config({
      "format" => {
        "format1" => 0,
        "format2" => 1,
        "format3" => 2,
        "format4" => 3,
        "format5" => 10,
      }
    })

    calculator = PropertyBoostCalculator.new

    assert_equal 0, calculator.boost(build_document(format: "format1"))
    assert_equal 0.5, calculator.boost(build_document(format: "format2"))
    assert_equal 0.75, calculator.boost(build_document(format: "format3"))
    assert_equal 0.88, calculator.boost(build_document(format: "format4"))
    assert_equal 1, calculator.boost(build_document(format: "format5"))
  end

  def test_unboosted_format_has_default_boost
    stub_boost_config({
      "format" => {
        "some_format" => 1,
      }
    })

    calculator = PropertyBoostCalculator.new

    assert_equal 0.5, calculator.boost(build_document(format: "some_format"))
  end

  def test_boosts_limit_is_1
    stub_boost_config({
      "format" => {
        "format1" => 10,
        "format2" => 100,
        "format3" => 1000,
      }
    })

    calculator = PropertyBoostCalculator.new

    assert_equal 1, calculator.boost(build_document(format: "format1"))
    assert_equal 1, calculator.boost(build_document(format: "format2"))
    assert_equal 1, calculator.boost(build_document(format: "format3"))
  end

  def test_unconfigured_format_has_default_boost
    stub_boost_config({
      "format" => {
        "some_format" => 0.3,
      }
    })

    calculator = PropertyBoostCalculator.new

    assert_equal 0.5, calculator.boost(build_document(format: "other_format"))
  end

  def test_unconfigured_property_has_default_boost
    stub_boost_config({
      "some_other_property" => {
        "some_value" => 0.3,
      }
    })

    calculator = PropertyBoostCalculator.new

    assert_equal 0.5, calculator.boost(build_document(document_type: "some_doc_type"))
  end

  def test_boosts_are_rounded
    stub_boost_config({
      "format" => {
        "format1" => 0.123,
        "format2" => 0.456,
      }
    })

    calculator = PropertyBoostCalculator.new

    assert_equal 0.08, calculator.boost(build_document(format: "format1"))
    assert_equal 0.27, calculator.boost(build_document(format: "format2"))
  end

  def test_boosts_for_different_fields_are_combined
    stub_boost_config({
      "format" => {
        "publication" => 0.5,
      },
      "content_store_document_type" => {
        "foi_release" => 0.2,
      },
      "navigation_document_supertype" => {
        "guidance" => 0.8
      }
    })

    calculator = PropertyBoostCalculator.new

    document = Document.new(sample_field_definitions, {
      "format" => "publication",
      "content_store_document_type" => "foi_release",
      "navigation_document_supertype" => "some_other_value"
    })

    #   1 - 2^(-format boost * document type boost * navigation supertype boost)
    # = 1 - 2^(-0.5 * 0.2 * 1)
    # = 0.07
    assert_equal 0.07, calculator.boost(document)
  end

  def stub_boost_config(boosts)
    YAML.stubs(:load_file).returns(boosts)
  end

  def build_document(format: nil, document_type: nil)
    attributes = {
      "_type" => "some_type",
    }
    attributes["format"] = format if format
    attributes["content_store_document_type"] = document_type if document_type

    Document.new(sample_field_definitions, attributes)
  end
end
