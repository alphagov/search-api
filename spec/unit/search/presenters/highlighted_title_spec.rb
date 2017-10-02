require 'spec_helper'

RSpec.describe Search::HighlightedTitle do
  it "title_highlighted" do
    title = described_class.new({
      "fields" => { "title" => "A Title" },
      "highlight" => { "title" => ["A Highlighted Title"] }
    })

    expect(title.text).to eq("A Highlighted Title")
  end

  it "fallback_title_is_escaped" do
    title = described_class.new({
      "fields" => { "title" => "A & Title" },
    })

    expect(title.text).to eq("A &amp; Title")
  end
end
