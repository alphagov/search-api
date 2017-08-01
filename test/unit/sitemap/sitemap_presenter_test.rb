require "test_helper"
require "sitemap/sitemap"

class SitemapPresenterTest < Minitest::Test
  def setup
    Plek.any_instance.stubs(:website_root).returns("https://website_root")
  end

  def test_url_is_document_link_if_link_is_http_url
    document = build_document(url: "http://some.url")
    presenter = SitemapPresenter.new(document)
    assert_equal "http://some.url", presenter.url
  end

  def test_url_is_document_link_if_link_is_https_url
    document = build_document(url: "https://some.url")
    presenter = SitemapPresenter.new(document)
    assert_equal "https://some.url", presenter.url
  end

  def test_url_appends_host_name_if_link_is_a_path
    document = build_document(url: "/some/path")
    presenter = SitemapPresenter.new(document)
    assert_equal "https://website_root/some/path", presenter.url
  end

  def test_last_updated_is_timestamp_if_timestamp_is_date_time
    document = build_document(
      url: "/some/path",
      timestamp: "2014-01-28T14:41:50+00:00"
    )
    presenter = SitemapPresenter.new(document)
    assert_equal "2014-01-28T14:41:50+00:00", presenter.last_updated
  end

  def test_last_updated_is_timestamp_if_timestamp_is_date
    document = build_document(
      url: "/some/path",
      timestamp: "2017-07-12"
    )
    presenter = SitemapPresenter.new(document)
    assert_equal "2017-07-12", presenter.last_updated
  end

  def test_last_updated_is_omitted_if_timestamp_is_missing
    document = build_document(
      url: "/some/path",
      timestamp: nil
    )
    presenter = SitemapPresenter.new(document)
    assert_nil presenter.last_updated
  end

  def test_last_updated_is_omitted_if_timestamp_is_invalid
    document = build_document(
      url: "/some/path",
      timestamp: "not-a-date"
    )
    presenter = SitemapPresenter.new(document)
    assert_nil presenter.last_updated
  end

  def test_last_updated_is_omitted_if_timestamp_is_in_invalid_format
    document = build_document(
      url: "/some/path",
      timestamp: "01-01-2017"
    )
    presenter = SitemapPresenter.new(document)
    assert_nil presenter.last_updated
  end

  def test_default_page_priority_is_maximum_value
    document = build_document(
      url: "/some/path",
      is_withdrawn: false
    )
    presenter = SitemapPresenter.new(document)
    assert_equal 1, presenter.priority
  end

  def test_withdrawn_page_has_lower_priority
    document = build_document(
      url: "/some/path",
      is_withdrawn: true
    )
    presenter = SitemapPresenter.new(document)
    assert_equal 0.25, presenter.priority
  end

  def test_page_with_no_withdrawn_flag_has_maximum_priority
    document = build_document(
      url: "/some/path"
    )
    presenter = SitemapPresenter.new(document)
    assert_equal 1, presenter.priority
  end

  def build_document(url:, timestamp: nil, is_withdrawn: nil)
    attributes = {
      "link" => url,
      "_type" => "some_type",
    }
    attributes["public_timestamp"] = timestamp if timestamp
    attributes["is_withdrawn"] = is_withdrawn if !is_withdrawn.nil?

    Document.new(sample_field_definitions, attributes)
  end
end
