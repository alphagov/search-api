# encoding: utf-8
require "integration_test_helper"

class MultipleBackendsTest < IntegrationTest
  def test_passes_search_to_chosen_backend
    chosen_backend = stub_everything("chosen backend")
    app.any_instance.stubs(:available_backends).returns(chosen: chosen_backend)
    chosen_backend.expects(:search).returns([])
    get "/chosen/search?q=example"
  end

  def test_actions_other_than_search_use_primary_backend_as_default
    primary_backend = stub_everything("primary backend")
    app.any_instance.stubs(:available_backends).returns(primary: primary_backend)
    primary_backend.expects(:get).returns({'example' => 'document'})
    get "/documents/abc"
  end

  def test_responds_with_404_if_backend_not_found
    app.any_instance.stubs(:available_backends).returns(chosen: nil)
    get "/chosen/search?q=example"
    assert_equal 404, last_response.status
  end
end