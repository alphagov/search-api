require 'spec_helper'
require "sitemap/sitemap"

RSpec.describe 'SitemapPresenterTest' do
  before do
    Plek.any_instance.stubs(:website_root).returns("https://website_root")

    @boost_calculator = PropertyBoostCalculator.new
    @boost_calculator.stubs(:boost).returns(1)
  end

  it "url_is_document_link_if_link_is_http_url" do
    document = build_document(url: "http://some.url")
    presenter = SitemapPresenter.new(document, @boost_calculator)
    assert_equal "http://some.url", presenter.url
  end

  it "url_is_document_link_if_link_is_https_url" do
    document = build_document(url: "https://some.url")
    presenter = SitemapPresenter.new(document, @boost_calculator)
    assert_equal "https://some.url", presenter.url
  end

  it "url_appends_host_name_if_link_is_a_path" do
    document = build_document(url: "/some/path")
    presenter = SitemapPresenter.new(document, @boost_calculator)
    assert_equal "https://website_root/some/path", presenter.url
  end

  it "last_updated_is_timestamp_if_timestamp_is_date_time" do
    document = build_document(
      url: "/some/path",
      timestamp: "2014-01-28T14:41:50+00:00"
    )
    presenter = SitemapPresenter.new(document, @boost_calculator)
    assert_equal "2014-01-28T14:41:50+00:00", presenter.last_updated
  end

  it "last_updated_is_timestamp_if_timestamp_is_date" do
    document = build_document(
      url: "/some/path",
      timestamp: "2017-07-12"
    )
    presenter = SitemapPresenter.new(document, @boost_calculator)
    assert_equal "2017-07-12", presenter.last_updated
  end

  it "last_updated_is_limited_to_recent_date" do
    document = build_document(
      url: "/some/path",
      timestamp: "1995-06-01"
    )
    presenter = SitemapPresenter.new(document, @boost_calculator)
    assert_equal "2012-10-17T00:00:00+00:00", presenter.last_updated
  end

  it "last_updated_is_omitted_if_timestamp_is_missing" do
    document = build_document(
      url: "/some/path",
      timestamp: nil
    )
    presenter = SitemapPresenter.new(document, @boost_calculator)
    assert_nil presenter.last_updated
  end

  it "last_updated_is_omitted_if_timestamp_is_invalid" do
    document = build_document(
      url: "/some/path",
      timestamp: "not-a-date"
    )
    presenter = SitemapPresenter.new(document, @boost_calculator)
    assert_nil presenter.last_updated
  end

  it "last_updated_is_omitted_if_timestamp_is_in_invalid_format" do
    document = build_document(
      url: "/some/path",
      timestamp: "01-01-2017"
    )
    presenter = SitemapPresenter.new(document, @boost_calculator)
    assert_nil presenter.last_updated
  end

  it "default_page_priority_is_maximum_value" do
    document = build_document(
      url: "/some/path",
      is_withdrawn: false
    )
    presenter = SitemapPresenter.new(document, @boost_calculator)
    assert_equal 1, presenter.priority
  end

  it "withdrawn_page_has_lower_priority" do
    document = build_document(
      url: "/some/path",
      is_withdrawn: true
    )
    presenter = SitemapPresenter.new(document, @boost_calculator)
    assert_equal 0.25, presenter.priority
  end

  it "page_with_no_withdrawn_flag_has_maximum_priority" do
    document = build_document(
      url: "/some/path"
    )
    presenter = SitemapPresenter.new(document, @boost_calculator)
    assert_equal 1, presenter.priority
  end

  it "page_with_boosted_format_has_adjusted_priority" do
    document = build_document(
      url: "/some/path",
      format: "aaib_report"
    )
    property_boost_calculator = PropertyBoostCalculator.new
    property_boost_calculator.stubs(:boost).with(document).returns(0.72)

    presenter = SitemapPresenter.new(document, property_boost_calculator)
    assert_equal 0.72, presenter.priority
  end

  def build_document(url:, timestamp: nil, format: nil, is_withdrawn: nil)
    attributes = {
      "link" => url,
      "_type" => "some_type",
    }
    attributes["public_timestamp"] = timestamp if timestamp
    attributes["format"] = format if format
    attributes["is_withdrawn"] = is_withdrawn if !is_withdrawn.nil?

    Document.new(sample_field_definitions, attributes)
  end
end
