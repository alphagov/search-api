require 'spec_helper'

RSpec.describe Search::HighlightedDescription do
  it "adds_highlighting_if_present" do
    raw_result = {
      "fields" => { "description" => "I will be hightlighted." },
      "highlight" => { "description" => ["I will be <mark>hightlighted</mark>."] }
    }

    highlighted_description = described_class.new(raw_result).text

    expect("I will be <mark>hightlighted</mark>.").to eq(highlighted_description)
  end

  it "uses_default_description_if_hightlight_not_found" do
    raw_result = {
      "fields" => { "description" => "I will not be hightlighted & escaped." }
    }

    highlighted_description = described_class.new(raw_result).text

    expect("I will not be hightlighted &amp; escaped.").to eq(highlighted_description)
  end

  it "truncates_default_description_if_hightlight_not_found" do
    raw_result = {
      "fields" => { "description" => ("This is a sentence that is too long." * 10) }
    }

    highlighted_description = described_class.new(raw_result).text

    expect(225).to eq(highlighted_description.size)
    expect(highlighted_description.ends_with?('…')).to be_truthy
  end

  it "returns_empty_string_if_theres_no_description" do
    raw_result = {
      "fields" => { "description" => nil }
    }

    highlighted_description = described_class.new(raw_result).text

    expect("").to eq(highlighted_description)
  end
end
