require 'test_helper'

class GovukIndex::IndexableContentSanitiserTest < Minitest::Test
  def test_strips_html_tags_from_indexable_content
    payload = [
      [
        { "content_type" => "text/govspeak", "content" => "**hello**" },
        { "content_type" => "text/html", "content" => "<strong>hello</strong> <a href='www.gov.uk'>marmaduke</a>" }
      ]
    ]

    assert_equal "hello marmaduke", content_sanitiser.clean(payload)
  end

  def test_passes_single_string_content_unchanged
    payload = ["hello marmaduke"]

    assert_equal "hello marmaduke", content_sanitiser.clean(payload)
  end

  def test_passes_multiple_string_items_unchanged
    payload = ["hello marmaduke", "hello marley"]

    assert_equal "hello marmaduke\n\n\nhello marley", content_sanitiser.clean(payload)
  end

  def test_strips_html_tags_from_string_content
    payload = ["<h1>hello marmaduke</h1>"]

    assert_equal "hello marmaduke", content_sanitiser.clean(payload)
  end

  def test_multiple_html_text_payload_items
    payload = [
      [
        { "content_type" => "text/govspeak", "content" => "**hello**" },
        { "content_type" => "text/html", "content" => "<strong>hello</strong>" }
      ],
      [
        { "content_type" => "text/govspeak", "content" => "**goodbye**" },
        { "content_type" => "text/html", "content" => "<strong>goodbye</strong>" }
      ],
    ]


    assert_equal "hello\ngoodbye", content_sanitiser.clean(payload)
  end

  def test_notifies_if_no_text_html_content
    payload = [
      [
        {
          "content" => "I love HTML Back end rules",
          "content_type" => "text/govspeak",
        }
      ]
    ]

    GovukError.expects(:notify).with(
      GovukIndex::MissingTextHtmlContentType.new,
      extra: { content_types: ["text/govspeak"] }
    )

    assert_equal nil, content_sanitiser.clean(payload)
  end

  def test_content_with_text_and_html_parts
    payload = [
      "title 1",
      [
        { "content_type" => "text/govspeak", "content" => "**hello**" },
        { "content_type" => "text/html", "content" => "<strong>hello</strong>" }
      ],
      "title 2",
      [
        { "content_type" => "text/govspeak", "content" => "**goodbye**" },
        { "content_type" => "text/html", "content" => "<strong>goodbye</strong>" }
      ],
    ]

    expected_content = "title 1\n\nhello\n\ntitle 2\n\ngoodbye"

    assert_equal expected_content, content_sanitiser.clean(payload)
  end

  def content_sanitiser
    GovukIndex::IndexableContentSanitiser.new
  end
end
