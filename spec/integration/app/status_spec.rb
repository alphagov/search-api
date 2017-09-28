require 'spec_helper'

RSpec.describe 'StatusTest', tags: ['integration'] do
  it "shows_queue_job_count" do
    expect_any_instance_of(Sidekiq::Stats).to receive(:queues).and_return(
      { "bulk" => 12 }
    )

    get "/_status"

    expect(last_response).to be_ok
    expect(["bulk"]).to eq(parsed_response["queues"].keys)
    expect(12).to eq(parsed_response["queues"]["bulk"]["jobs"])
  end

  it "shows_per_queue_retry_count" do
    retries = %w(bulk bulk something-else).map { |q| double(queue: q) }

    expect(Sidekiq::RetrySet).to receive(:new).and_return(retries)
    expect_any_instance_of(Sidekiq::Stats).to receive(:queues).and_return(
      { "bulk" => 12 }
    )

    get "/_status"

    expect(last_response).to be_ok
    expect(2).to eq(parsed_response["queues"]["bulk"]["retries"])
  end

  it "shows_zero_retry_count" do
    expect(Sidekiq::RetrySet).to receive(:new).and_return([])
    expect_any_instance_of(Sidekiq::Stats).to receive(:queues).and_return(
      { "bulk" => 12 }
    )

    get "/_status"

    expect(last_response).to be_ok
    expect(0).to eq(parsed_response["queues"]["bulk"]["retries"])
  end

  it "shows_per_queue_scheduled_count" do
    scheduled = %w(bulk bulk something-else).map { |q| double(queue: q) }

    expect(Sidekiq::ScheduledSet).to receive(:new).and_return(scheduled)
    expect_any_instance_of(Sidekiq::Stats).to receive(:queues).and_return(
      { "bulk" => 12 }
    )

    get "/_status"

    expect(last_response).to be_ok
    expect(2).to eq(parsed_response["queues"]["bulk"]["scheduled"])
  end

  it "shows_zero_retry_count_scheduled" do
    expect(Sidekiq::ScheduledSet).to receive(:new).and_return([])
    expect_any_instance_of(Sidekiq::Stats).to receive(:queues).and_return(
      { "bulk" => 12 }
    )

    get "/_status"

    expect(last_response).to be_ok
    expect(0).to eq(parsed_response["queues"]["bulk"]["scheduled"])
  end
end
