require "test_helper"
require "highlighted_description"

class HighlightedDescriptionTest < MiniTest::Unit::TestCase
  def test_adds_highlighting_if_present
    raw_result = {
      "fields" => { "description" => "I will be hightlighted." },
      "highlight" => { "description" => ["I will be <em>hightlighted</em>."] }
    }

    highlighted_description = HighlightedDescription.new(raw_result).text

    assert_equal "I will be <em>hightlighted</em>.", highlighted_description
  end

  def test_uses_default_description_if_hightlight_not_found
    raw_result = {
      "fields" => { "description" => "I will not be hightlighted & escaped." }
    }

    highlighted_description = HighlightedDescription.new(raw_result).text

    assert_equal "I will not be hightlighted &amp; escaped.", highlighted_description
  end

  def test_truncates_default_description_if_hightlight_not_found
    raw_result = {
      "fields" => { "description" => ("This is a sentence that is too long." * 10) }
    }

    highlighted_description = HighlightedDescription.new(raw_result).text

    assert_equal 225, highlighted_description.size
    assert highlighted_description.ends_with?('…')
  end

  def test_returns_empty_string_if_theres_no_description
    raw_result = {
      "fields" => { "description" => nil }
    }

    highlighted_description = HighlightedDescription.new(raw_result).text

    assert_equal "", highlighted_description
  end
end
