require 'spec_helper'

RSpec.describe Search::HighlightedTitle do
  it "highlights the title" do
    title = described_class.new({
      "_source" => { "title" => "A Title" },
      "highlight" => { "title" => ["A Highlighted Title"] }
    })

    expect(title.text).to eq("A Highlighted Title")
  end

  it "highlights the title with synonyms" do
    title = described_class.new({
      "_source" => { "title.synonym" => "A Title" },
      "highlight" => { "title.synonym" => ["A Highlighted Title"] }
    })

    expect(title.text).to eq("A Highlighted Title")
  end

  it "escapes the title when it falls back to the unhighlighted title" do
    title = described_class.new({
      "_source" => { "title" => "A & Title" },
    })

    expect(title.text).to eq("A &amp; Title")
  end
end
