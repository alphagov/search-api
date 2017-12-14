require 'spec_helper'

RSpec.describe "Policy publishing" do
  before do
    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "policies.test",
      processor: GovukIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock
    )

    @queue = @channel.queue("policies.test")
    consumer.run
  end

  let(:people) do
    [
      {
        "content_id" => SecureRandom.uuid,
        "title" => "Person 1",
        "base_path" => "/government/people/person-1",
        "locale" => "en",
      },
      {
        "content_id" => SecureRandom.uuid,
        "title" => "Person 2",
        "base_path" => "/government/people/person-2",
        "locale" => "en",
      },
    ]
  end

  let(:working_groups) do
    [
      {
        "content_id" => SecureRandom.uuid,
        "title" => "Working group 1",
        "base_path" => "/government/groups/working-group-1",
        "locale" => "en",
      },
      {
        "content_id" => SecureRandom.uuid,
        "title" => "Working group 2",
        "base_path" => "/government/groups/working-group-2",
        "locale" => "en",
      },
    ]
  end

  it "indexes a policy" do
    random_example = generate_random_example(
      schema: "policy",
      payload: {
        document_type: "policy",
        base_path: "/government/policies/hs2-high-speed-rail",
        expanded_links: {
          working_groups: working_groups,
          people: people
        }
      },
      details: { summary: "<p>Description about policy.</p>\n" },
    )

    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("policy" => :all)

    @queue.publish(random_example.to_json, content_type: "application/json")

    expected_document = {
       "link" => random_example["base_path"],
       "people" => ["person-1", "person-2"],
       "policy_groups" => ["working-group-1", "working-group-2"],
       "description" => "Description about policy.",
       "slug" => "hs2-high-speed-rail",
     }

    expect_document_is_in_rummager(expected_document, index: "govuk_test", type: "policy")
  end
end
