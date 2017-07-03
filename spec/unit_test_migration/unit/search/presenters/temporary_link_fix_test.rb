require "test_helper"
require "search/presenters/result_presenter"

class TemporaryLinkFixTest < MiniTest::Unit::TestCase
  def test_appending_a_slash_to_the_link_field
    document = {
      '_type' => 'raib_report',
      '_index' => 'mainstream_test',
      'fields' => { 'link' => ['some/link'] }
    }

    result = Search::ResultPresenter.new(document, nil, sample_schema, Search::QueryParameters.new(return_fields: %w[link])).present

    assert_equal "/some/link", result["link"]
  end

  def test_keep_http_links_intact
    document = {
      '_type' => 'raib_report',
      '_index' => 'mainstream_test',
      'fields' => { 'link' => ['http://example.org/some-link'] }
    }

    result = Search::ResultPresenter.new(document, nil, sample_schema, Search::QueryParameters.new(return_fields: %w[link])).present

    assert_equal "http://example.org/some-link", result["link"]
  end

  def test_keep_correct_links_intact
    document = {
      '_type' => 'raib_report',
      '_index' => 'mainstream_test',
      'fields' => { 'link' => ['/some-link'] }
    }

    result = Search::ResultPresenter.new(document, nil, sample_schema, Search::QueryParameters.new(return_fields: %w[link])).present

    assert_equal "/some-link", result["link"]
  end
end
