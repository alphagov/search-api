require "test_helper"
require "sitemap/sitemap"

class PropertyBoostCalculatorTest < Minitest::Test
  def test_documents_are_boosted_relative_to_default_for_property
    stub_boost_config({
      "format" => {
        "organisation" => 2.5,
        "service_manual_guide" => 0.3,
        "mainstream_browse_page" => 0,
      }
    })

    calculator = PropertyBoostCalculator.new

    assert_equal 1, calculator.boost(build_document(format: "organisation"))
    assert_equal 0.12, calculator.boost(build_document(format: "service_manual_guide"))
    assert_equal 0, calculator.boost(build_document(format: "mainstream_browse_page"))
  end

  def test_unconfigured_format_has_default_boost
    max_boost = 2.5
    stub_boost_config({ "format" => { "some_format" => max_boost } })

    calculator = PropertyBoostCalculator.new

    expected_default_boost = 1 / max_boost

    assert_equal expected_default_boost, calculator.boost(build_document(format: "a_different_format"))
  end

  def test_unconfigured_property_has_default_boost
    max_boost = 2.5
    stub_boost_config({ "format" => { "some_format" => max_boost } })

    calculator = PropertyBoostCalculator.new

    expected_default_boost = 1 / max_boost

    assert_equal expected_default_boost, calculator.boost(build_document(format: nil))
  end

  def test_document_without_property_has_default_boost
    max_boost = 2.5

    stub_boost_config({
      "some_property" => {
        "some_value" => max_boost,
      }
    })

    field_definitions = {}
    attributes = {}
    document_without_property = Document.new(field_definitions, attributes)

    calculator = PropertyBoostCalculator.new

    expected_default_boost = 1 / max_boost
    assert_equal expected_default_boost, calculator.boost(document_without_property)
  end

  def test_default_is_1_if_configured_properties_are_all_downweighted
    stub_boost_config({
      "format" => {
        "organisation" => 0.2,
        "service_manual_guide" => 0.3,
        "mainstream_browse_page" => 0,
      }
    })

    calculator = PropertyBoostCalculator.new

    assert_equal 0.2, calculator.boost(build_document(format: "organisation"))
    assert_equal 1, calculator.boost(build_document(format: "other_format"))
  end

  def test_boosts_for_different_fields_are_multiplied
    stub_boost_config({
      "format" => {
        "organisation" => 2,
        "publication" => 1,
      },
      "content_store_document_type" => {
        "foi_release" => 0.2
      },
      "navigation_document_supertype" => {
        "guidance" => 2.5
      }
    })

    calculator = PropertyBoostCalculator.new

    document = Document.new(sample_field_definitions, {
      "format" => "publication",
      "content_store_document_type" => "foi_release",
      "navigation_document_supertype" => "other"
    })

    # format boost * document type boost * navigation supertype boost
    # (1/2) * 0.2 * (1/2.5) = 0.04
    assert_equal 0.04, calculator.boost(document)
  end

  def test_boosts_are_not_rounded_by_integer_division
    stub_boost_config({
      "format" => {
        "top_format" => 4,
        "other_format" => 1,
      }
    })

    calculator = PropertyBoostCalculator.new

    assert_equal 0.25, calculator.boost(build_document(format: "other_format"))
  end

  def test_boosts_are_rounded
    stub_boost_config({
      "format" => {
        "top_format" => 3,
        "other_format" => 2,
      }
    })

    calculator = PropertyBoostCalculator.new

    assert_equal 0.67, calculator.boost(build_document(format: "other_format"))
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
