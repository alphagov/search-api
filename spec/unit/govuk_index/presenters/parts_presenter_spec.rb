require "spec_helper"

RSpec.describe GovukIndex::PartsPresenter do
  subject(:presented_parts) { described_class.new(parts: parts).presented_parts }

  context "when there are parts" do
    let(:parts) do
      [
        {
          "title" => "title 1",
          "slug" => "title-1",
          "body" => [
            { "content_type" => "text/govspeak", "content" => "**hello**" },
            { "content_type" => "text/html", "content" => "<strong>hello</strong>" },
          ],
        },
        {
          "title" => "title 2",
          "slug" => "title-2",
          "body" => [
            { "content_type" => "text/govspeak", "content" => "Universal Credit is a payment to help with your living costs. It’s paid monthly - or [twice a month for some people in Scotland](/universal-credit/how-youre-paid). \r\n\r\nYou may be able to get it if you're on a low income or out of work. \r\n\r\n^ This guide is also available in [Welsh (Cymraeg)](/credyd-cynhwysol).\r\n\r\nIf you live in Northern Ireland, go to [Universal Credit in Northern Ireland](https://www.nidirect.gov.uk/universalcredit).\r\n" },
            { "content_type" => "text/html", "content" => "<p>Universal Credit is a payment to help with your living costs. It’s paid monthly - or <a href=\"/universal-credit/how-youre-paid\">twice a month for some people in Scotland</a>.</p>\n\n<p>You may be able to get it if you’re on a low income or out of work.</p>\n\n<div role=\"note\" aria-label=\"Information\" class=\"application-notice info-notice\">\n<p>This guide is also available in <a href=\"/credyd-cynhwysol\">Welsh (Cymraeg)</a>.</p>\n</div>\n\n<p>If you live in Northern Ireland, go to <a rel=\"external\" href=\"https://www.nidirect.gov.uk/universalcredit\">Universal Credit in Northern Ireland</a>." },
          ],
        },
      ]
    end

    it "extracts parts" do
      expect(presented_parts).to eq([
        {
          "body" => "hello",
          "slug" => "title-1",
          "title" => "title 1",
        },
        {
          "body" => "Universal Credit is a payment to help with your living costs. It’s paid…",
          "slug" => "title-2",
          "title" => "title 2",
        },
      ])
    end
  end

  context "when parts is nil" do
    let(:parts) { nil }
    it { is_expected.to be_nil }
  end

  context "when parts is empty" do
    let(:parts) { [] }
    it { is_expected.to be_nil }
  end

  context "when there are no content/html parts" do
    let(:parts) do
      [{
        "title" => "title 1",
        "slug" => "title-1",
        "body" => [{ "content_type" => "text/govspeak", "content" => "**hello**" }],
      }]
    end
    it "raises an error" do
      expect(GovukError).to receive(:notify).with(
        GovukIndex::MissingTextHtmlContentType.new,
        extra: { content_types: ["text/govspeak"] },
      )
      expect(presented_parts).to eq([{ "body" => nil, "slug" => "title-1", "title" => "title 1" }])
    end
  end
end
