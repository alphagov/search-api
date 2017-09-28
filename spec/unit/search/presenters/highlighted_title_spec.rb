require 'spec_helper'

RSpec.describe Search::HighlightedTitle do
  it "title_highlighted" do
    title = described_class.new({
      "fields" => { "title" => "A Title" },
      "highlight" => { "title" => ["A Highlighted Title"] }
    })

    expect("A Highlighted Title").to eq(title.text)
  end

  it "fallback_title_is_escaped" do
    title = described_class.new({
      "fields" => { "title" => "A & Title" },
    })

    expect("A &amp; Title").to eq(title.text)
  end
end
