require 'spec_helper'

RSpec.describe GovukIndex::DetailsPresenter do
  subject { described_class.new(details: details, format: format) }

  context "licence format" do
    let(:format) { 'licence' }
    let(:details) {
      {
        "continuation_link" => "http://www.on-and-on.com",
        "external_related_links" => [],
        "licence_identifier" => "1234-5-6",
        "licence_short_description" => "short description",
        "licence_overview" => [
          { "content_type" => "text/govspeak", "content" => "**overview**" },
          { "content_type" => "text/html", "content" => "<strong>overview</strong>" }
        ],
        "will_continue_on" => "on and on",
      }
    }

    it "should extract licence specific fields" do
      expect(subject.licence_identifier).to eq(details["licence_identifier"])
      expect(subject.licence_short_description).to eq(details["licence_short_description"])
    end
  end
end
