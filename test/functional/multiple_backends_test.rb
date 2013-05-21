# encoding: utf-8
require "integration_test_helper"

class MultipleBackendsTest < IntegrationTest
  def test_passes_search_to_chosen_backend
    chosen_index = mock("chosen index", search: stub(results: []))
    Elasticsearch::SearchServer.any_instance.expects(:index).with("chosen").returns(chosen_index)
    get "/chosen/search?q=example"
  end

  def test_actions_other_than_search_use_primary_backend_as_default
    default_index = mock("default index", get: { 'example' => 'document' })
    Elasticsearch::SearchServer.any_instance.expects(:index).with("mainstream").returns(default_index)
    get "/documents/abc"
  end

  def test_responds_with_404_if_backend_not_found
    Elasticsearch::SearchServer.any_instance.expects(:index).with("chosen").raises(Elasticsearch::NoSuchIndex)
    get "/chosen/search?q=example"
    assert_equal 404, last_response.status
  end
end
