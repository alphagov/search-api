require 'spec_helper'

RSpec.describe GovukIndex::IndexableContentSanitiser do
  it "strips_html_tags_from_indexable_content" do
    payload = [
      [
        { "content_type" => "text/govspeak", "content" => "**hello**" },
        { "content_type" => "text/html", "content" => "<strong>hello</strong> <a href='www.gov.uk'>marmaduke</a>" }
      ]
    ]

    expect(subject.clean(payload)).to eq("hello marmaduke")
  end

  it "passes_single_string_content_unchanged" do
    payload = ["hello marmaduke"]

    expect(subject.clean(payload)).to eq("hello marmaduke")
  end

  it "passes_multiple_string_items_unchanged" do
    payload = ["hello marmaduke", "hello marley"]

    expect(subject.clean(payload)).to eq("hello marmaduke\n\n\nhello marley")
  end

  it "strips_html_tags_from_string_content" do
    payload = ["<h1>hello marmaduke</h1>"]

    expect(subject.clean(payload)).to eq("hello marmaduke")
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


    expect(subject.clean(payload)).to eq("hello\ngoodbye")
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

    expect(GovukError).to receive(:notify).with(
      GovukIndex::MissingTextHtmlContentType.new,
      extra: { content_types: ["text/govspeak"] }
    )

    expect(nil).to eq(subject.clean(payload))
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

    expect(expected_content).to eq(subject.clean(payload))
  end
end
