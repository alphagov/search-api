require "integration_test_helper"
require "gds_api/test_helpers/content_api"

class AlphaTaxonomyFilterTest < IntegrationTest
  include GdsApi::TestHelpers::ContentApi

  def setup
    stub_elasticsearch_settings
    create_test_indexes
    TaxonomyPrototype::TaxonFinder.stubs(:find_by).returns(["foo", "bar"])
  end

  def teardown
    clean_test_indexes
  end

  def test_filtering_on_a_taxon
    content_api_has_an_artefact("an-example-artefact")
    post "/documents", {
      "link" => "/an-example-artefact"
    }.to_json
    assert last_response.ok?
    post "/mainstream_test/commit"

    get "/unified_search.json?filter_alpha_taxonomy[]=bar"

    assert_equal 1, parsed_response["total"]
    assert_equal "/an-example-artefact", parsed_response["results"].first["link"]
  end
end
