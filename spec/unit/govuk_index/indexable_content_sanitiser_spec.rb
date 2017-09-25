require 'spec_helper'

RSpec.describe 'GovukIndex::IndexableContentSanitiserTest' do
  it "strips_html_tags_from_indexable_content" do
    payload = [
      [
        { "content_type" => "text/govspeak", "content" => "**hello**" },
        { "content_type" => "text/html", "content" => "<strong>hello</strong> <a href='www.gov.uk'>marmaduke</a>" }
      ]
    ]

    assert_equal "hello marmaduke", content_sanitiser.clean(payload)
  end

  it "passes_single_string_content_unchanged" do
    payload = ["hello marmaduke"]

    assert_equal "hello marmaduke", content_sanitiser.clean(payload)
  end

  it "passes_multiple_string_items_unchanged" do
    payload = ["hello marmaduke", "hello marley"]

    assert_equal "hello marmaduke\n\n\nhello marley", content_sanitiser.clean(payload)
  end

  it "strips_html_tags_from_string_content" do
    payload = ["<h1>hello marmaduke</h1>"]

    assert_equal "hello marmaduke", content_sanitiser.clean(payload)
  end

  it "multiple_html_text_payload_items" do
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

  it "notifies_if_no_text_html_content" do
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

  it "content_with_text_and_html_parts" do
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
