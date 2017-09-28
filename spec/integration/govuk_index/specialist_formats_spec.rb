require 'spec_helper'

RSpec.describe 'SpecialistFormatTest', tags: ['integration'] do
  before do
    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "bigwig.test",
      processor: GovukIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock
    )

    @queue = @channel.queue("bigwig.test")
    consumer.run
  end

  it "specialist_publisher_finders_are_correctly_indexed" do
    random_example = generate_random_example(
      schema: "finder",
      payload: { document_type: "finder" },
      regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" }
    )

    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return(["finder"])

    @queue.publish(random_example.to_json, content_type: "application/json")

    expect_document_is_in_rummager({ "link" => random_example["base_path"] }, index: "govuk_test", type: 'edition')
  end

  it "specialist_documents_are_correctly_indexed" do
    document_types = %w(
      aaib_report
      asylum_support_decision
      business_finance_support_scheme
      cma_case
      countryside_stewardship_grant
      dfid_research_output
      drug_safety_update
      employment_appeal_tribunal_decision
      employment_tribunal_decision
      international_development_fund
      maib_report
      medical_safety_alert
      raib_report
      service_standard_report
      tax_tribunal_decision
      utaac_decision
      vehicle_recalls_and_faults_alert
    )

    # ideally we would run a test for all document types, but this takes 3 seconds so I have limited
    # it to a random subset
    document_types.sample(3).each do |specialist_document_type|
      random_example = generate_random_example(
        schema: "specialist_document",
        payload: { document_type: specialist_document_type },
        regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" }
      )
      allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return([specialist_document_type])

      @queue.publish(random_example.to_json, content_type: "application/json")

      expect_document_is_in_rummager({ "link" => random_example["base_path"] }, index: "govuk_test", type: specialist_document_type)
    end
  end

  it "esi_documents_are_correctly_indexed" do
    publisher_document_type = 'esi_fund'
    search_document_type = 'european_structural_investment_fund'

    random_example = generate_random_example(
      schema: "specialist_document",
      payload: { document_type: publisher_document_type },
      regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" }
    )
    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return([publisher_document_type])

    @queue.publish(random_example.to_json, content_type: "application/json")

    expect_document_is_in_rummager({ "link" => random_example["base_path"] }, index: "govuk_test", type: search_document_type)
  end

  it "finders_email_signup_are_never_indexed" do
    random_example = generate_random_example(
      schema: "finder_email_signup",
      payload: { document_type: "finder_email_signup" },
      regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" }
    )

    @queue.publish(random_example.to_json, content_type: "application/json")

    expect {
      fetch_document_from_rummager(id: random_example["base_path"], index: "govuk_test")
    }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
  end
end
