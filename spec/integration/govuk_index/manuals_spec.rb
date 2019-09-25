require "spec_helper"

RSpec.describe "Manual publishing" do
  before do
    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "manuals.test",
      processor: GovukIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock,
    )

    @queue = @channel.queue("manuals.test")
    consumer.run
  end

  it "indexes a Manual" do
    random_example = generate_random_example(
      schema: "manual",
      payload: {
        document_type: "manual",
        description: "Manual description",
      },
      details: {
        change_notes: [
          {
            change_note: "Some description of change",
            title: "Name of manual section",
            published_at: "2017-06-21T10:48:34+00:00",
            base_path: "/some/section/base/path",
          },
        ],
      },
    )

    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("manual" => :all)

    @queue.publish(random_example.to_json, content_type: "application/json")

    expected_document = {
      "link" => random_example["base_path"],
      "indexable_content" => nil,
      "description" => "Manual description",
      "latest_change_note" => nil,
    }

    expect_document_is_in_rummager(expected_document, index: "govuk_test", type: "manual")
  end

  it "indexes a manual section" do
    random_example = generate_random_example(
      schema: "manual_section",
      payload: { document_type: "manual_section" },
      details: {
        manual: {
          "base_path": "/parent/manual/path",
        },
      },
    )

    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("manual_section" => :all)

    @queue.publish(random_example.to_json, content_type: "application/json")

    expected_document = {
       "link" => random_example["base_path"],
       "title" => random_example["title"],
       "manual" => "/parent/manual/path",
     }
    expect_document_is_in_rummager(expected_document, index: "govuk_test", type: "manual_section")
  end
end
