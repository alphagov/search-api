require 'spec_helper'

RSpec.describe 'StatusTest', tags: ['integration'] do
  it "shows_queue_job_count" do
    Sidekiq::Stats.any_instance.expects(:queues).returns(
      { "bulk" => 12 }
    )

    get "/_status"

    assert last_response.ok?
    assert_equal ["bulk"], parsed_response["queues"].keys
    assert_equal 12, parsed_response["queues"]["bulk"]["jobs"]
  end

  it "shows_per_queue_retry_count" do
    retries = %w(bulk bulk something-else).map { |q| stub(queue: q) }

    Sidekiq::RetrySet.expects(:new).returns(retries)
    Sidekiq::Stats.any_instance.expects(:queues).returns(
      { "bulk" => 12 }
    )

    get "/_status"

    assert last_response.ok?
    assert_equal 2, parsed_response["queues"]["bulk"]["retries"]
  end

  it "shows_zero_retry_count" do
    Sidekiq::RetrySet.expects(:new).returns([])
    Sidekiq::Stats.any_instance.expects(:queues).returns(
      { "bulk" => 12 }
    )

    get "/_status"

    assert last_response.ok?
    assert_equal 0, parsed_response["queues"]["bulk"]["retries"]
  end

  it "shows_per_queue_scheduled_count" do
    scheduled = %w(bulk bulk something-else).map { |q| stub(queue: q) }

    Sidekiq::ScheduledSet.expects(:new).returns(scheduled)
    Sidekiq::Stats.any_instance.expects(:queues).returns(
      { "bulk" => 12 }
    )

    get "/_status"

    assert last_response.ok?
    assert_equal 2, parsed_response["queues"]["bulk"]["scheduled"]
  end

  it "shows_zero_retry_count_scheduled" do
    Sidekiq::ScheduledSet.expects(:new).returns([])
    Sidekiq::Stats.any_instance.expects(:queues).returns(
      { "bulk" => 12 }
    )

    get "/_status"

    assert last_response.ok?
    assert_equal 0, parsed_response["queues"]["bulk"]["scheduled"]
  end
end
