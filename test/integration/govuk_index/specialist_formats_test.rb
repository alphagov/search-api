require 'integration_test_helper'

class SpecialistFormatTest < IntegrationTest
  def setup
    super

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

  def test_specialist_publisher_finders_are_correctly_indexed
    random_example = GovukSchemas::RandomExample
                       .for_schema(notification_schema: "finder")
                       .merge_and_validate(document_type: "finder")
    GovukIndex::MigratedFormats.stubs(:indexable_formats).returns(["finder"])

    @queue.publish(random_example.to_json, content_type: "application/json")

    assert_document_is_in_rummager({ "link" => random_example["base_path"] }, index: "govuk_test", type: 'edition')
  end

  def test_specialist_documents_are_correctly_indexed
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
      random_example = GovukSchemas::RandomExample
                         .for_schema(notification_schema: "specialist_document")
                         .merge_and_validate(document_type: specialist_document_type)
      GovukIndex::MigratedFormats.stubs(:indexable_formats).returns([specialist_document_type])

      @queue.publish(random_example.to_json, content_type: "application/json")

      assert_document_is_in_rummager({ "link" => random_example["base_path"] }, index: "govuk_test", type: specialist_document_type)
    end
  end

  def test_esi_documents_are_correctly_indexed
    publisher_document_type = 'esi_fund'
    search_document_type = 'european_structural_investment_fund'

    random_example = GovukSchemas::RandomExample
                       .for_schema(notification_schema: "specialist_document")
                       .merge_and_validate(document_type: publisher_document_type)
    GovukIndex::MigratedFormats.stubs(:indexable_formats).returns([publisher_document_type])

    @queue.publish(random_example.to_json, content_type: "application/json")

    assert_document_is_in_rummager({ "link" => random_example["base_path"] }, index: "govuk_test", type: search_document_type)
  end

  def test_finders_email_signup_are_never_indexed
    random_example = GovukSchemas::RandomExample
                       .for_schema(notification_schema: "finder_email_signup")
                       .merge_and_validate(document_type: "finder_email_signup")
    @queue.publish(random_example.to_json, content_type: "application/json")

    assert_raises(Elasticsearch::Transport::Transport::Errors::NotFound) do
      fetch_document_from_rummager(id: random_example["base_path"], index: "govuk_test")
    end
  end
end
