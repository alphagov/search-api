require 'test_helper'

class GovukIndex::IndexableContentSanitiserTest < Minitest::Test
  def test_strips_html_tags_from_indexable_content
    payload = {
      "base_path" => "/some/path",
      "document_type" => "aaib_report",
      "details" => {
        "body" => [
          { "content_type" => "text/govspeak", "content" => "**hello**" },
          { "content_type" => "text/html", "content" => "<strong>hello</strong> <a href='www.gov.uk'>marmaduke</a>" }
        ]
      }
    }

    assert_equal "hello marmaduke", content_sanitiser.clean(payload)
  end

  def test_passes_single_string_content_unchanged
    payload = {
      "base_path" => "/some/path",
      "document_type" => "aaib_report",
      "details" => { "body" => "hello marmaduke" }
    }

    assert_equal "\nhello marmaduke\n", content_sanitiser.clean(payload)
  end

  def test_passes_multiple_string_items_unchanged
    payload = {
      "base_path" => "/some/path",
      "document_type" => "aaib_report",
      "details" => {
        "body" =>  "hello marmaduke",
        "other" => "hello marley"
      }
    }

    assert_equal "\nhello marmaduke\n\n\nhello marley\n", content_sanitiser.clean(payload)
  end

  def test_strips_html_tags_from_string_content
    payload = {
      "base_path" => "/some/path",
      "document_type" => "aaib_report",
      "details" => { "body" => "<h1>hello marmaduke</h1>" }
    }

    assert_equal "\nhello marmaduke\n", content_sanitiser.clean(payload)
  end

  def test_multiple_html_text_payload_items
    payload = {
      "base_path" => "/some/path",
      "document_type" => "aaib_report",
      "details" => {
        "body" => [
          { "content_type" => "text/govspeak", "content" => "**hello**" },
          { "content_type" => "text/html", "content" => "<strong>hello</strong>" }
        ],
        "other" => [
          { "content_type" => "text/govspeak", "content" => "**goodbye**" },
          { "content_type" => "text/html", "content" => "<strong>goodbye</strong>" }
        ],
      },
    }

    assert_equal "hello\ngoodbye", content_sanitiser.clean(payload)
  end

  def test_notifies_if_no_text_html_content
    payload = {
      "base_path" => "/some/path",
      "document_type" => "aaib_report",
      "details" => {
        "body" => [
          {
            "content" => "I love HTML Back end rules",
            "content_type" => "text/govspeak",
          }
        ]
      }
    }

    GOVUK::Error.expects(:notify).with(
      GovukIndex::MissingTextHtmlContentType.new,
      parameters: { content_types: ["text/govspeak"] }
    )

    assert_equal nil, content_sanitiser.clean(payload)
  end

  def content_sanitiser
    GovukIndex::IndexableContentSanitiser.new
  end
end
