require 'govuk_schemas'
require 'integration_test_helper'
require 'govuk_index/publishing_event_processor'

class GovukIndex::UnpublishingMessageProcessing < IntegrationTest
  def test_unpublish_message_will_remove_record_from_elasticsearch
    message = create_message('unpublishing', payload_version: 2)
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

  def test_unpublish_withdrawn_messages_will_set_is_withdrawn_flag
    message = create_message(
      'help_page',
      payload_version: 2,
      withdrawn_notice: {
        "explanation" => "<div class=\"govspeak\"><p>test 2</p>\n</div>",
        "withdrawn_at" => "2017-08-03T14:02:18Z"
      }
    )
    base_path = message.payload['base_path']
    type = message.payload['document_type']

    commit_document('govuk_test', { 'link' => base_path }, type: type)

    assert_document_is_in_rummager({ 'link' => base_path, 'is_withdrawn' => nil }, index: 'govuk_test', type: type)
    processor = GovukIndex::PublishingEventProcessor.new
    processor.process(message)

    commit_index('govuk_test')
    assert_document_is_in_rummager({ 'link' => base_path, 'is_withdrawn' => true }, index: 'govuk_test', type: type)
  end

  def create_message(schema_name, user_defined = {})
    payload = GovukSchemas::RandomExample
      .for_schema(notification_schema: schema_name)
      .merge_and_validate(user_defined)
    stubs(:message).tap do |message|
      message.stubs(:ack)
      message.stubs(:payload).returns(payload)
      message.stubs(:delivery_info).returns(routing_key: 'test.unpublish')
    end
  end
end
