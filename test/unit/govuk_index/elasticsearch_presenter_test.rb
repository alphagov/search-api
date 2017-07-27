require "test_helper"
require "govuk_index/elasticsearch_presenter"

class GovukIndex::ElasticsearchPresenterTest < MiniTest::Unit::TestCase
  def test_converts_message_payload_to_elasticsearch_format
    payload = {
      "base_path" => "/some/path",
      "document_type" => "aaib_report",
      "title" => "A plane has had an issue"
    }

    presenter = GovukIndex::ElasticsearchPresenter.new(payload)

    expected_identifier = {
      _type: "aaib_report",
      _id: "/some/path"
    }

    expected_document = {
      link: "/some/path",
      title: "A plane has had an issue"
    }

    assert_equal expected_identifier, presenter.identifier
    assert_equal expected_document, presenter.document
  end
end
