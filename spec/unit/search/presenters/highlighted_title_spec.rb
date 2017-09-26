require 'spec_helper'

RSpec.describe Search::HighlightedTitle do
  it "title_highlighted" do
    title = described_class.new({
      "fields" => { "title" => "A Title" },
      "highlight" => { "title" => ["A Highlighted Title"] }
    })

    assert_equal "A Highlighted Title", title.text
  end

  it "fallback_title_is_escaped" do
    title = described_class.new({
      "fields" => { "title" => "A & Title" },
    })

    assert_equal "A &amp; Title", title.text
  end
end
