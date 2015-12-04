require "test_helper"
require "gds_api/test_helpers/content_api"
require "indexer"

describe Indexer::TagLookup do
  include GdsApi::TestHelpers::ContentApi

  describe '#prepare_tags' do
    it 'returns an unchanged document if there are no tags for the document' do
      stub_request(:get, "#{Plek.find('contentapi')}/no-link.json").to_return(status: 404)

      result = Indexer::TagLookup.prepare_tags({ "link" => "/no-link"})

      assert_equal({ "link" => "/no-link" }, result)
    end

    it 'returns an unchanged document if the document is HTTP Gone' do
      stub_request(:get, "#{Plek.find('contentapi')}/no-link.json").to_return(status: 410)

      result = Indexer::TagLookup.prepare_tags({ "link" => "/no-link", "specialist_sectors" => ["foo", "foo", "bar"] })

      assert_equal({"link" => "/no-link", "specialist_sectors" => ["foo", "foo", "bar"]}, result)
    end

    it 'returns an unchanged document for external URLs' do
      result = Indexer::TagLookup.prepare_tags({ "link" => "http://example.com/some-link"})

      assert_equal({ "link" => "http://example.com/some-link" }, result)
    end

    it 'adds the tags from the tagging-api to the document' do
      content_api_has_an_artefact("foo/bar", {
        "tags" => [
          tag_for_slug("benefits/advice", "section"),
          tag_for_slug("benefits/more-advice", "specialist_sector"),
          tag_for_slug("hmrc", "organisation"),
        ]
      })

      result = Indexer::TagLookup.prepare_tags({ "link" => "/foo/bar"})

      assert_equal ["benefits/more-advice"], result["specialist_sectors"]
      assert_equal ["benefits/advice"], result["mainstream_browse_pages"]
      assert_equal ["hmrc"], result["organisations"]
    end

    it 'merges tags from the tagging-api with those already in the document' do
      content_api_has_an_artefact("foo/bar", {
        "tags" => [
          tag_for_slug("bar", "specialist_sector"),
          tag_for_slug("foo", "specialist_sector"),
        ]
      })

      result = Indexer::TagLookup.prepare_tags({ "link" => "/foo/bar", "specialist_sectors" => ["foo", "foo", "baz"] })

      assert_equal ["foo", "baz", "bar"], result["specialist_sectors"]
    end
  end
end
