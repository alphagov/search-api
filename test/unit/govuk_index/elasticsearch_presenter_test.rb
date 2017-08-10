require 'test_helper'

class GovukIndex::ElasticsearchPresenterTest < Minitest::Test
  def test_converts_message_payload_to_elasticsearch_format
    payload = {
      "base_path" => "/some/path",
      "document_type" => "aaib_report",
      "title" => "A plane has had an issue",
      "payload_version" => 1,
      "version_type" => "external"
    }

    presenter = GovukIndex::ElasticsearchPresenter.new(payload, "aaib_report")

    expected_identifier = {
      _type: "aaib_report",
      _id: "/some/path",
      version: 1,
      version_type: "external"
    }

    expected_document = {
      link: "/some/path",
      title: "A plane has had an issue",
      is_withdrawn: false,
    }

    assert_equal expected_identifier, presenter.identifier
    assert_equal expected_document, presenter.document
  end

  def test_converts_gone_message_payload_to_elasticsearch_format
    payload = {
      "base_path" => "/some/path",
      "document_type" => "gone",
      "payload_version" => 1,
      "version_type" => "external"
    }

    presenter = GovukIndex::ElasticsearchPresenter.new(payload, "aaib_report")

    expected_identifier = {
      _type: "aaib_report",
      _id: "/some/path",
      version: 1,
      version_type: "external"
    }

    assert_equal expected_identifier, presenter.identifier
  end

  def test_withdrawn_when_withdrawn_notice_present
    payload = {
      "base_path" => "/some/path",
      "document_type" => "aaib_report",
      "title" => "A plane has had an issue",
      "payload_version" => 2,
      "version_type" => "external",
      "withdrawn_notice" => {
        "explanation" => "<div class=\"govspeak\"><p>test 2</p>\n</div>",
        "withdrawn_at" => "2017-08-03T14:02:18Z"
      }
    }

    presenter = GovukIndex::ElasticsearchPresenter.new(payload, "aaib_report")

    expected_identifier = {
      _type: "aaib_report",
      _id: "/some/path",
      version: 2,
      version_type: "external"
    }

    expected_document = {
      link: "/some/path",
      title: "A plane has had an issue",
      is_withdrawn: true,
    }

    assert_equal expected_identifier, presenter.identifier
    assert_equal expected_document, presenter.document
  end
end
