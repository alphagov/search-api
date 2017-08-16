require 'test_helper'

class GovukIndex::ElasticsearchPresenterTest < Minitest::Test
  def setup
    super

    @popularity_lookup = stub(:popularity_lookup)
    Indexer::PopularityLookup.stubs(:new).returns(@popularity_lookup)
    @popularity_lookup.stubs(:lookup_popularities).returns({})
  end

  def test_converts_message_payload_to_elasticsearch_format
    payload = {
      "base_path" => "/some/path",
      "document_type" => "aaib_report",
      "title" => "A plane has had an issue",
      "payload_version" => 1,
      "version_type" => "external",
      "details" => { "body" => "We love cheese" }
    }

    presenter = elasticsearch_presenter(payload)

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
      content_store_document_type: "aaib_report",
      popularity: nil,
      indexable_content: "\nWe love cheese\n",
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

    presenter = elasticsearch_presenter(payload)

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

    presenter = elasticsearch_presenter(payload)

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
      content_store_document_type: "aaib_report",
      popularity: nil,
      indexable_content: nil,
    }

    assert_equal expected_identifier, presenter.identifier
    assert_equal expected_document, presenter.document
  end

  def test_popularity_when_value_is_returned_from_lookup
    payload = {
      "base_path" => "/some/path",
      "document_type" => "aaib_report",
    }

    popularity = 0.0125356

    Indexer::PopularityLookup.expects(:new).with('govuk_index', SearchConfig.instance).returns(@popularity_lookup)
    @popularity_lookup.expects(:lookup_popularities).with([payload['base_path']]).returns(payload["base_path"] => popularity)

    presenter = elasticsearch_presenter(payload)

    assert_equal popularity, presenter.document[:popularity]
  end

  def test_no_popularity_when_no_value_is_returned_from_lookup
    payload = {
      "base_path" => "/some/path",
      "document_type" => "aaib_report",
    }

    Indexer::PopularityLookup.expects(:new).with('govuk_index', SearchConfig.instance).returns(@popularity_lookup)
    @popularity_lookup.expects(:lookup_popularities).with([payload['base_path']]).returns({})

    presenter = elasticsearch_presenter(payload)

    assert_equal nil, presenter.document['popularity']
  end

  def elasticsearch_presenter(payload)
    GovukIndex::ElasticsearchPresenter.new(
      payload: payload,
      type: "aaib_report",
      sanitiser: GovukIndex::IndexableContentSanitiser.new
    )
  end
end
