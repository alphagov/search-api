require 'spec_helper'
require "sitemap/sitemap"

RSpec.describe SitemapPresenter do
  before do
    allow_any_instance_of(Plek).to receive(:website_root).and_return("https://website_root")

    @boost_calculator = PropertyBoostCalculator.new
    allow(@boost_calculator).to receive(:boost).and_return(1)
  end

  it "url_is_document_link_if_link_is_http_url" do
    document = build_document(url: "http://some.url")
    presenter = described_class.new(document, @boost_calculator)
    expect("http://some.url").to eq(presenter.url)
  end

  it "url_is_document_link_if_link_is_https_url" do
    document = build_document(url: "https://some.url")
    presenter = described_class.new(document, @boost_calculator)
    expect("https://some.url").to eq(presenter.url)
  end

  it "url_appends_host_name_if_link_is_a_path" do
    document = build_document(url: "/some/path")
    presenter = described_class.new(document, @boost_calculator)
    expect("https://website_root/some/path").to eq(presenter.url)
  end

  it "last_updated_is_timestamp_if_timestamp_is_date_time" do
    document = build_document(
      url: "/some/path",
      timestamp: "2014-01-28T14:41:50+00:00"
    )
    presenter = described_class.new(document, @boost_calculator)
    expect("2014-01-28T14:41:50+00:00").to eq(presenter.last_updated)
  end

  it "last_updated_is_timestamp_if_timestamp_is_date" do
    document = build_document(
      url: "/some/path",
      timestamp: "2017-07-12"
    )
    presenter = described_class.new(document, @boost_calculator)
    expect("2017-07-12").to eq(presenter.last_updated)
  end

  it "last_updated_is_limited_to_recent_date" do
    document = build_document(
      url: "/some/path",
      timestamp: "1995-06-01"
    )
    presenter = described_class.new(document, @boost_calculator)
    expect("2012-10-17T00:00:00+00:00").to eq(presenter.last_updated)
  end

  it "last_updated_is_omitted_if_timestamp_is_missing" do
    document = build_document(
      url: "/some/path",
      timestamp: nil
    )
    presenter = described_class.new(document, @boost_calculator)
    expect(presenter.last_updated).to be_nil
  end

  it "last_updated_is_omitted_if_timestamp_is_invalid" do
    document = build_document(
      url: "/some/path",
      timestamp: "not-a-date"
    )
    presenter = described_class.new(document, @boost_calculator)
    expect(presenter.last_updated).to be_nil
  end

  it "last_updated_is_omitted_if_timestamp_is_in_invalid_format" do
    document = build_document(
      url: "/some/path",
      timestamp: "01-01-2017"
    )
    presenter = described_class.new(document, @boost_calculator)
    expect(presenter.last_updated).to be_nil
  end

  it "default_page_priority_is_maximum_value" do
    document = build_document(
      url: "/some/path",
      is_withdrawn: false
    )
    presenter = described_class.new(document, @boost_calculator)
    expect(1).to eq(presenter.priority)
  end

  it "withdrawn_page_has_lower_priority" do
    document = build_document(
      url: "/some/path",
      is_withdrawn: true
    )
    presenter = described_class.new(document, @boost_calculator)
    expect(0.25).to eq(presenter.priority)
  end

  it "page_with_no_withdrawn_flag_has_maximum_priority" do
    document = build_document(
      url: "/some/path"
    )
    presenter = described_class.new(document, @boost_calculator)
    expect(1).to eq(presenter.priority)
  end

  it "page_with_boosted_format_has_adjusted_priority" do
    document = build_document(
      url: "/some/path",
      format: "aaib_report"
    )
    property_boost_calculator = PropertyBoostCalculator.new
    allow(property_boost_calculator).to receive(:boost).with(document).and_return(0.72)

    presenter = described_class.new(document, property_boost_calculator)
    expect(0.72).to eq(presenter.priority)
  end

  def build_document(url:, timestamp: nil, format: nil, is_withdrawn: nil)
    document = {
      "link" => url,
      "_type" => "some_type",
    }
    document["public_timestamp"] = timestamp if timestamp
    document["format"] = format if format
    document["is_withdrawn"] = is_withdrawn if !is_withdrawn.nil?

    document
  end
end
