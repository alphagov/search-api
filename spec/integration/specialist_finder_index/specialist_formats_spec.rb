require "spec_helper"

RSpec.describe "SpecialistFormatTest" do
  before do
    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "bigwig.test",
      processor: SpecialistFinderIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock,
    )

    @queue = @channel.queue("bigwig.test")
    consumer.run
  end

  it "specialist publisher finders are correctly indexed" do
    random_example = generate_random_example(
      schema: "finder",
      payload: { document_type: "finder" },
    )

    @queue.publish(random_example.to_json, content_type: "application/json")

    expect_document_is_in_rummager({ "link" => random_example["base_path"] }, index: "specialist-finder_test", type: "finder")
  end

  it "specialist documents are correctly indexed" do
    document_types = %w[
      aaib_report
      asylum_support_decision
      business_finance_support_scheme
      cma_case
      countryside_stewardship_grant
      drug_safety_update
      employment_appeal_tribunal_decision
      employment_tribunal_decision
      flood_and_coastal_erosion_risk_management_research_report
      international_development_fund
      licence_transaction
      maib_report
      medical_safety_alert
      protected_food_drink_name
      raib_report
      research_for_development_output
      residential_property_tribunal_decision
      service_standard_report
      statutory_instrument
      tax_tribunal_decision
      utaac_decision
    ]

    # ideally we would run a test for all document types, but this takes 3 seconds so I have limited
    # it to a random subset
    document_types.sample(3).each do |specialist_document_type|
      random_example = generate_random_example(
        schema: "specialist_document",
        payload: { document_type: specialist_document_type },
      )

      @queue.publish(random_example.to_json, content_type: "application/json")

      expect_document_is_in_rummager({ "link" => random_example["base_path"] }, index: "specialist-finder_test", type: specialist_document_type)
    end
  end

  it "esi documents are correctly indexed" do
    publisher_document_type = "esi_fund"

    random_example = generate_random_example(
      schema: "specialist_document",
      payload: { document_type: publisher_document_type },
    )

    @queue.publish(random_example.to_json, content_type: "application/json")

    expect_document_is_in_rummager(
      { "link" => random_example["base_path"], "format" => publisher_document_type },
      index: "specialist-finder_test",
      type: publisher_document_type,
    )
  end

  it "finders email signup are never indexed" do
    random_example = generate_random_example(
      schema: "finder_email_signup",
      payload: { document_type: "finder_email_signup" },
    )

    @queue.publish(random_example.to_json, content_type: "application/json")

    expect {
      fetch_document_from_rummager(id: random_example["base_path"], index: "specialist-finder_test")
    }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
  end
end
