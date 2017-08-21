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
      "content_id" => "XXX-XXX-XXX-XXX",
      "content_store_document_type" => "help_page",
      "description" => "This page will help you love cheese too",
      "details" => { "body" => "We love cheese" },
      "document_type" => "help_page",
      "expanded_links" => {
        "organisations" => [
          {
            "content_id" => "YYY-YYY-YYY",
            "title" => "The Great Cheese Organisation",
          }
        ]
      },
      "payload_version" => 1,
      "public_updated_at" => "2016-02-29T09:24:10Z",
      "publishing_app" => "rails_for_the_win",
      "rendering_app" => "react_rules_ok",
      "title" => "This is a help page",
    }

    presenter = elasticsearch_presenter(payload, "help_page")

    expected_identifier = {
      _type: "help_page",
      _id: "/some/path",
      version: 1,
      version_type: "external"
    }

    expected_document = {
      content_id: "XXX-XXX-XXX-XXX",
      content_store_document_type: "help_page",
      description: "This page will help you love cheese too",
      format: "help_page",
      indexable_content: "\nWe love cheese\n",
      is_withdrawn: false,
      link: "/some/path",
      mainstream_browse_pages: [],
      mainstream_browse_page_content_ids: [],
      organisations: ["The Great Cheese Organisation"],
      organisation_content_ids: ["YYY-YYY-YYY"],
      part_of_taxonomy_tree: [],
      primary_publishing_organisation: [],
      popularity: nil,
      public_timestamp: "2016-02-29T09:24:10Z",
      publishing_app: "rails_for_the_win",
      rendering_app: "react_rules_ok",
      specialist_sectors: [],
      taxons: [],
      topic_content_ids: [],
      title: "This is a help page",
    }

    assert_equal expected_identifier, presenter.identifier
    assert_equal expected_document, presenter.document
  end

  def test_withdrawn_when_withdrawn_notice_present
    payload = {
      "base_path" => "/some/path",
      "withdrawn_notice" => {
        "explanation" => "<div class=\"govspeak\"><p>test 2</p>\n</div>",
        "withdrawn_at" => "2017-08-03T14:02:18Z"
      }
    }

    presenter = elasticsearch_presenter(payload)

    assert_equal presenter.document[:is_withdrawn], true
  end

  def test_popularity_when_value_is_returned_from_lookup
    payload = { "base_path" => "/some/path" }

    popularity = 0.0125356

    Indexer::PopularityLookup.expects(:new).with('govuk_index', SearchConfig.instance).returns(@popularity_lookup)
    @popularity_lookup.expects(:lookup_popularities).with([payload['base_path']]).returns(payload["base_path"] => popularity)

    presenter = elasticsearch_presenter(payload)

    assert_equal popularity, presenter.document[:popularity]
  end

  def test_no_popularity_when_no_value_is_returned_from_lookup
    payload = { "base_path" => "/some/path" }

    Indexer::PopularityLookup.expects(:new).with('govuk_index', SearchConfig.instance).returns(@popularity_lookup)
    @popularity_lookup.expects(:lookup_popularities).with([payload['base_path']]).returns({})

    presenter = elasticsearch_presenter(payload)

    assert_equal nil, presenter.document['popularity']
  end

  def elasticsearch_presenter(payload, type = "aaib_report")
    GovukIndex::ElasticsearchPresenter.new(
      payload: payload,
      type: type,
      sanitiser: GovukIndex::IndexableContentSanitiser.new
    )
  end
end
