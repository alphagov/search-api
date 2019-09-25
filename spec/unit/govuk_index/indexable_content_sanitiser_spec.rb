require "spec_helper"

RSpec.describe GovukIndex::IndexableContentSanitiser do
  it "passes content without html tags unchanged" do
    payload = ["hello marmaduke"]

    expect(subject.clean(payload)).to eq("hello marmaduke")
  end

  it "can process multiple string items" do
    payload = ["hello marmaduke", "hello marley"]

    expect(subject.clean(payload)).to eq("hello marmaduke\n\n\nhello marley")
  end

  it "strips html tags from string content" do
    payload = ["<h1>hello marmaduke</h1>"]

    expect(subject.clean(payload)).to eq("hello marmaduke")
  end

  context "when an array of strings is passed in" do
    it "treats each element of the array as a valid element" do
      payload = [
        [
          "line 1",
          "line 2"
        ]
      ]

      expect(subject.clean(payload)).to eq("line 1\n\n\nline 2")
    end

    it "strips html tags from each element in the array" do
      payload = [
        [
          "<p>line 1<\p>",
          "<div>line<\div> 2"
        ]
      ]

      expect(subject.clean(payload)).to eq("line 1\n\n\n\nline\n 2")
    end
  end

  context "when html test payloads exists" do
    it "strips out html tags from to the html content" do
      payload = [
        [
          { "content_type" => "text/govspeak", "content" => "**hello**" },
          { "content_type" => "text/html", "content" => "<strong>hello</strong> <a href='www.gov.uk'>marmaduke</a>" }
        ]
      ]

      expect(subject.clean(payload)).to eq("hello marmaduke")
    end

    it "joins the multiple payload items together" do
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

    it "notifies if no text html content" do
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

      expect(subject.clean(payload)).to be_nil
    end
  end

  it "can process both text and html parts" do
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

    expect(subject.clean(payload)).to eq(expected_content)
  end

  context "Does not perform HTML encoding for" do
    it '\r character' do
      payload = ["line 1\r\nline 2"]
      expected_content = "line 1\r\nline 2"
      expect(subject.clean(payload)).to eql(expected_content)
    end

    it "& character" do
      payload = ["line 1 & line 2"]
      expected_content = "line 1 & line 2"
      expect(subject.clean(payload)).to eql(expected_content)
    end

    it "accent characters" do
      payload = ["crème brûlée"]
      expected_content = "crème brûlée"
      expect(subject.clean(payload)).to eql(expected_content)
    end

    it "% character" do
      payload = ["100%"]
      expected_content = "100%"
      expect(subject.clean(payload)).to eql(expected_content)
    end
  end
end
