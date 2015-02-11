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

    parsed_response = JSON.parse(last_response.body)
    assert_equal ["bulk"], parsed_response["queues"].keys
    assert_equal 12, parsed_response["queues"]["bulk"]["jobs"]
  end

  def test_shows_per_queue_retry_count
    # Stubbing out Sidekiq's retries (SortedEntry instances)
    # https://github.com/mperham/sidekiq/blob/v2.13.0/lib/sidekiq/api.rb#L203-248
    retries = %w(bulk bulk something-else).map { |q| stub(queue: q) }

    Sidekiq::RetrySet.expects(:new).returns(retries)
    Sidekiq::Stats.any_instance.expects(:queues).returns(
      {"bulk" => 12}
    )

    get "/_status"

    assert last_response.ok?
    parsed_response = JSON.parse(last_response.body)
    assert_equal 2, parsed_response["queues"]["bulk"]["retries"]
  end

  def test_shows_zero_retry_count
    Sidekiq::RetrySet.expects(:new).returns([])
    Sidekiq::Stats.any_instance.expects(:queues).returns(
      {"bulk" => 12}
    )

    get "/_status"

    assert last_response.ok?
    parsed_response = JSON.parse(last_response.body)
    assert_equal 0, parsed_response["queues"]["bulk"]["retries"]
  end

  def test_shows_per_queue_scheduled_count
    # Stubbing out Sidekiq's schedule list (SortedEntry instances)
    # https://github.com/mperham/sidekiq/blob/v2.13.0/lib/sidekiq/api.rb#L203-248
    scheduled = %w(bulk bulk something-else).map { |q| stub(queue: q) }

    Sidekiq::ScheduledSet.expects(:new).returns(scheduled)
    Sidekiq::Stats.any_instance.expects(:queues).returns(
      {"bulk" => 12}
    )

    get "/_status"

    assert last_response.ok?
    parsed_response = JSON.parse(last_response.body)
    assert_equal 2, parsed_response["queues"]["bulk"]["scheduled"]
  end

  def test_shows_zero_retry_count
    Sidekiq::ScheduledSet.expects(:new).returns([])
    Sidekiq::Stats.any_instance.expects(:queues).returns(
      {"bulk" => 12}
    )

    get "/_status"

    assert last_response.ok?
    parsed_response = JSON.parse(last_response.body)
    assert_equal 0, parsed_response["queues"]["bulk"]["scheduled"]
  end
end
