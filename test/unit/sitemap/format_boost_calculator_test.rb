require "test_helper"
require "sitemap/sitemap"

class FormatBoostCalculatorTest < Minitest::Test
  def setup
    @calculator = FormatBoostCalculator.new
  end

  def test_unconfigured_format_has_default_boost
    expected_max_boost = 2.5
    expected_default_boost = 1 / expected_max_boost

    assert_equal expected_default_boost, @calculator.boost("some_other_format")
  end

  def test_formats_are_boosted_relative_to_default
    assert_equal 1, @calculator.boost("organisation")
    assert_equal 0.12, @calculator.boost("service_manual_guide")
    assert_equal 0, @calculator.boost("mainstream_browse_page")
  end

  def test_boosts_are_not_rounded_by_integer_division
    boosts = {
      "format_boosts" => {
        "top_format" => 4,
        "other_format" => 1,
      },
    }

    YAML.stubs(:load_file).returns(boosts)

    calculator = FormatBoostCalculator.new

    assert_equal 0.25, calculator.boost("other_format")
  end

  def test_boosts_are_rounded
    boosts = {
      "format_boosts" => {
        "top_format" => 3,
        "other_format" => 2,
      },
    }

    YAML.stubs(:load_file).returns(boosts)

    calculator = FormatBoostCalculator.new

    assert_equal 0.67, calculator.boost("other_format")
  end
end
