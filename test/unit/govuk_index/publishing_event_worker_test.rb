require "test_helper"
require 'support/test_index_helpers'
require 'govuk_index/elasticsearch_presenter'
require 'govuk_index/publishing_event_worker'

class PublishingEventWorkerTest < MiniTest::Unit::TestCase
  def test_should_save_valid_message
    payload = {
      "base_path" => "/cheese",
      "document_type" => "cheddar",
      "title" => "We love cheese"
    }

    saver = stub('saver')
    GovukIndex::ElasticsearchSaver.expects(:new).returns(saver)
    saver.expects(:save)

    GovukIndex::PublishingEventWorker.new.perform(payload)
  end

  def test_should_notify_when_validation_error
    invalid_payload = {
      "document_type" => "cheddar",
      "title" => "We love cheese"
    }

    Airbrake.expects(:notify_or_ignore).with(
      instance_of(GovukIndex::ValidationError),
      parameters: { message_body: { 'document_type' => 'cheddar', 'title' => 'We love cheese' } }
    )

    GovukIndex::PublishingEventWorker.new.perform(invalid_payload)
  end
end
