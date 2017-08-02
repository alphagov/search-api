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
