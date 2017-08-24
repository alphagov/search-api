require 'test_helper'

class GovukIndex::IndexableContentPresenterTest < Minitest::Test
  def test_details_with_govspeak_and_text_html
    details = {
      "body" => [
        { "content_type" => "text/govspeak", "content" => "**hello**" },
        { "content_type" => "text/html", "content" => "<strong>hello</strong>" }
      ],
      "other" => [
        { "content_type" => "text/govspeak", "content" => "**goodbye**" },
        { "content_type" => "text/html", "content" => "<strong>goodbye</strong>" }
      ],
    }

    assert_equal "hello\ngoodbye", indexable_content_presenter(details).indexable_content
  end

  def test_details_with_parts
    details = {
      "parts" => [
        {
          "title" => "title 1",
          "body" => [
            { "content_type" => "text/govspeak", "content" => "**hello**" },
            { "content_type" => "text/html", "content" => "<strong>hello</strong>" }
          ],
        },
        {
          "title" => "title 2",
          "body" => [
            { "content_type" => "text/govspeak", "content" => "**goodbye**" },
            { "content_type" => "text/html", "content" => "<strong>goodbye</strong>" }
          ],
        }
      ]
    }

    assert_equal "title 1\n\nhello\n\ntitle 2\n\ngoodbye", indexable_content_presenter(details).indexable_content
  end

  def indexable_content_presenter(details)
    GovukIndex::IndexableContentPresenter.new(details)
  end
end
