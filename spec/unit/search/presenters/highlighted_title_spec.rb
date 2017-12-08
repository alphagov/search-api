require 'spec_helper'

RSpec.describe Search::HighlightedTitle do
  it "highlights the title" do
    title = described_class.new({
      "fields" => { "title" => "A Title" },
      "highlight" => { "title" => ["A Highlighted Title"] }
    })

    expect(title.text).to eq("A Highlighted Title")
  end

  it "escapes the title when it falls back to the unhighlighted title" do
    title = described_class.new({
      "fields" => { "title" => "A & Title" },
    })

    expect(title.text).to eq("A &amp; Title")
  end
end
