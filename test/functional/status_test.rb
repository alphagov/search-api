require "integration_test_helper"  # Because it tests the Sinatra app

class StatusTest < IntegrationTest
  def test_shows_queue_job_count
    Sidekiq::Stats.any_instance.expects(:queues).returns(
      {"bulk" => 12}
    )
    get "/_status"
    assert last_response.ok?
    # Don't mind whether the response type has a charset
    assert_equal "application/json", last_response.content_type.split(";")[0]

    parsed_response = MultiJson.decode(last_response.body)
    assert_equal ["bulk"], parsed_response["queues"].keys
    assert_equal 12, parsed_response["queues"]["bulk"]["jobs"]
  end
end
