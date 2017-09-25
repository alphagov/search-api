require 'spec_helper'

RSpec.describe 'HighlightedTitleTest' do
  it "title_highlighted" do
    title = Search::HighlightedTitle.new({
      "fields" => { "title" => "A Title" },
      "highlight" => { "title" => ["A Highlighted Title"] }
    })

    assert_equal "A Highlighted Title", title.text
  end

  it "fallback_title_is_escaped" do
    title = Search::HighlightedTitle.new({
      "fields" => { "title" => "A & Title" },
    })

    assert_equal "A &amp; Title", title.text
  end
end
