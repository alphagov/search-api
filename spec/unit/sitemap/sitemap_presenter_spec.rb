require "spec_helper"

RSpec.describe SitemapPresenter do
  before do
    allow_any_instance_of(Plek).to receive(:website_root).and_return("https://website_root")

    @boost_calculator = PropertyBoostCalculator.new
    allow(@boost_calculator).to receive(:boost).and_return(1)
  end

  it "url is document link if link is http url" do
    document = build_document(url: "http://some.url")
    presented = described_class.new(document, @boost_calculator).to_h
    expect(presented[:url]).to eq("http://some.url")
  end

  it "url is document link if link is https url" do
    document = build_document(url: "https://some.url")
    presented = described_class.new(document, @boost_calculator).to_h
    expect(presented[:url]).to eq("https://some.url")
  end

  it "url appends host name if link is a path" do
    document = build_document(url: "/some/path")
    presented = described_class.new(document, @boost_calculator).to_h
    expect(presented[:url]).to eq("https://website_root/some/path")
  end

  it "last updated is timestamp if timestamp is date time" do
    document = build_document(
      url: "/some/path",
      timestamp: "2014-01-28T14:41:50+00:00",
    )
    presented = described_class.new(document, @boost_calculator).to_h
    expect(presented[:last_updated]).to eq("2014-01-28T14:41:50+00:00")
  end

  it "updated_at overrides public_timestamp if both are present" do
    document = build_document(url: "/some/path")
    document["public_timestamp"] = "2014-01-28T14:41:50+00:00"
    document["updated_at"] = "2019-01-28T14:41:50+00:00"
    presented = described_class.new(document, @boost_calculator).to_h
    expect(presented[:last_updated]).to eq("2019-01-28T14:41:50+00:00")
  end

  it "last updated is timestamp if timestamp is date" do
    document = build_document(
      url: "/some/path",
      timestamp: "2017-07-12",
    )
    presented = described_class.new(document, @boost_calculator).to_h
    expect(presented[:last_updated]).to eq("2017-07-12T00:00:00+00:00")
  end

  it "last updated is limited to recent date" do
    document = build_document(
      url: "/some/path",
      timestamp: "1995-06-01",
    )
    presented = described_class.new(document, @boost_calculator).to_h
    expect(presented[:last_updated]).to eq("2012-10-17T00:00:00+00:00")
  end

  it "last updated is omitted if timestamp is missing" do
    document = build_document(
      url: "/some/path",
      timestamp: nil,
    )
    presented = described_class.new(document, @boost_calculator).to_h
    expect(presented[:last_updated]).to be_nil
  end

  it "last updated is omitted if timestamp is invalid" do
    document = build_document(
      url: "/some/path",
      timestamp: "not-a-date",
    )
    presented = described_class.new(document, @boost_calculator).to_h
    expect(presented[:last_updated]).to be_nil
  end

  it "page with boosted format has adjusted priority" do
    document = build_document(
      url: "/some/path",
      format: "aaib_report",
    )
    property_boost_calculator = PropertyBoostCalculator.new
    allow(property_boost_calculator).to receive(:boost).with(document).and_return(0.72)

    presented = described_class.new(document, property_boost_calculator).to_h
    expect(0.72).to eq(presented[:priority])
  end

  def build_document(url:, timestamp: nil, format: nil, is_withdrawn: nil)
    document = {
      "link" => url,
      "document_type" => "some_type",
    }
    document["public_timestamp"] = timestamp if timestamp
    document["format"] = format if format
    document["is_withdrawn"] = is_withdrawn unless is_withdrawn.nil?

    document
  end
end
