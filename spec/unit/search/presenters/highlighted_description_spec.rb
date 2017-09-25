require 'spec_helper'

RSpec.describe 'HighlightedDescriptionTest' do
  it "adds_highlighting_if_present" do
    raw_result = {
      "fields" => { "description" => "I will be hightlighted." },
      "highlight" => { "description" => ["I will be <mark>hightlighted</mark>."] }
    }

    highlighted_description = Search::HighlightedDescription.new(raw_result).text

    assert_equal "I will be <mark>hightlighted</mark>.", highlighted_description
  end

  it "uses_default_description_if_hightlight_not_found" do
    raw_result = {
      "fields" => { "description" => "I will not be hightlighted & escaped." }
    }

    highlighted_description = Search::HighlightedDescription.new(raw_result).text

    assert_equal "I will not be hightlighted &amp; escaped.", highlighted_description
  end

  it "truncates_default_description_if_hightlight_not_found" do
    raw_result = {
      "fields" => { "description" => ("This is a sentence that is too long." * 10) }
    }

    highlighted_description = Search::HighlightedDescription.new(raw_result).text

    assert_equal 225, highlighted_description.size
    assert highlighted_description.ends_with?('…')
  end

  it "returns_empty_string_if_theres_no_description" do
    raw_result = {
      "fields" => { "description" => nil }
    }

    highlighted_description = Search::HighlightedDescription.new(raw_result).text

    assert_equal "", highlighted_description
  end
end
