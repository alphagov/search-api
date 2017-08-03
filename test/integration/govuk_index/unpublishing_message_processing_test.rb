require 'govuk_schemas'
require 'integration_test_helper'
require 'govuk_index/publishing_event_processor'

class GovukIndex::UnpusblishingMessageProcessing < IntegrationTest
  def test_unpublish_message_will_remove_record_from_elasticsearch
    message = create_message(publisher_schema: 'unpublishing')
    base_path = message.payload['base_path']
    type = message.payload['document_type']

    commit_document('govuk_test', { 'link' => base_path }, type: type)

    assert_document_is_in_rummager({ 'link' => base_path }, index: 'govuk_test', type: type)
    processor = GovukIndex::PublishingEventProcessor.new
    processor.process(message)

    commit_index('govuk_test')
    assert_raises(Elasticsearch::Transport::Transport::Errors::NotFound) do
      fetch_document_from_rummager(id: base_path, index: 'govuk_test', type: type)
    end
  end

  def create_message(schema_name)
    stubs(:message).tap do |message|
      message.stubs(:ack)
      message.stubs(:payload).returns(GovukSchemas::RandomExample.for_schema(schema_name).payload)
      message.stubs(:delivery_info).returns(routing_key: 'test.unpublish')
    end
  end
end
