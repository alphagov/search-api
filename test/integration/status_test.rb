require "integration_test_helper"

class StatusTest < IntegrationTest
  def test_shows_queue_job_count
    Sidekiq::Stats.any_instance.expects(:queues).returns(
      { "bulk" => 12 }
    )

    get "/_status"

    assert last_response.ok?
    assert_equal ["bulk"], parsed_response["queues"].keys
    assert_equal 12, parsed_response["queues"]["bulk"]["jobs"]
  end

  def test_shows_per_queue_retry_count
    retries = %w(bulk bulk something-else).map { |q| stub(queue: q) }

    Sidekiq::RetrySet.expects(:new).returns(retries)
    Sidekiq::Stats.any_instance.expects(:queues).returns(
      { "bulk" => 12 }
    )

    get "/_status"

    assert last_response.ok?
    assert_equal 2, parsed_response["queues"]["bulk"]["retries"]
  end

  def test_shows_zero_retry_count
    Sidekiq::RetrySet.expects(:new).returns([])
    Sidekiq::Stats.any_instance.expects(:queues).returns(
      { "bulk" => 12 }
    )

    get "/_status"

    assert last_response.ok?
    assert_equal 0, parsed_response["queues"]["bulk"]["retries"]
  end

  def test_shows_per_queue_scheduled_count
    scheduled = %w(bulk bulk something-else).map { |q| stub(queue: q) }

    Sidekiq::ScheduledSet.expects(:new).returns(scheduled)
    Sidekiq::Stats.any_instance.expects(:queues).returns(
      { "bulk" => 12 }
    )

    get "/_status"

    assert last_response.ok?
    assert_equal 2, parsed_response["queues"]["bulk"]["scheduled"]
  end

  def test_shows_zero_retry_count_scheduled
    Sidekiq::ScheduledSet.expects(:new).returns([])
    Sidekiq::Stats.any_instance.expects(:queues).returns(
      { "bulk" => 12 }
    )

    get "/_status"

    assert last_response.ok?
    assert_equal 0, parsed_response["queues"]["bulk"]["scheduled"]
  end
end
