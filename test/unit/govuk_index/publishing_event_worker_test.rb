require 'test_helper'

class PublishingEventWorkerTest < Minitest::Test
  def test_save_valid_message
    payload = {
      "base_path" => "/cheese",
      "document_type" => "help_page",
      "title" => "We love cheese"
    }

    actions = stub('actions')
    GovukIndex::ElasticsearchProcessor.expects(:new).returns(actions)
    actions.expects(:save)
    actions.expects(:commit).returns('items' => [{ 'index' => { 'status' => 200 } }])

    Services.statsd_client.expects(:increment).with('govuk_index.sidekiq-consumed')
    Services.statsd_client.expects(:increment).with('govuk_index.elasticsearch.index')
    GovukIndex::PublishingEventWorker.new.perform('routing.key', payload)
  end

  def test_delete_record_when_unpublishing_message_received
    payload = {
      "base_path" => "/cheese",
      "document_type" => "redirect",
      "title" => "We love cheese"
    }
    stub_document_type_inferer

    actions = stub('actions')
    GovukIndex::ElasticsearchProcessor.expects(:new).returns(actions)
    actions.expects(:delete)
    actions.expects(:commit).returns('items' => [{ 'delete' => { 'status' => 200 } }])

    Services.statsd_client.expects(:increment).with('govuk_index.sidekiq-consumed')
    Services.statsd_client.expects(:increment).with('govuk_index.elasticsearch.delete')
    GovukIndex::PublishingEventWorker.new.perform('routing.unpublish', payload)
  end

  def test_should_not_delete_withdrawn
    payload = {
      "base_path" => "/cheese",
      "document_type" => "help_page",
      "title" => "We love cheese",
      "withdrawn_notice" => {
        "explanation" => "<div class=\"govspeak\"><p>test 2</p>\n</div>",
        "withdrawn_at" => "2017-08-03T14:02:18Z"
      }
    }

    actions = stub('actions')
    GovukIndex::ElasticsearchProcessor.expects(:new).returns(actions)
    actions.expects(:save)
    actions.expects(:commit).returns('items' => [{ 'index' => { 'status' => 200 } }])

    Services.statsd_client.expects(:increment).with('govuk_index.sidekiq-consumed')
    Services.statsd_client.expects(:increment).with('govuk_index.elasticsearch.index')

    GovukIndex::PublishingEventWorker.new.perform('routing.unpublish', payload)
  end

  def test_raise_error_when_elasticsearch_update_error
    payload = {
      "base_path" => "/cheese",
      "document_type" => "gone",
      "title" => "We love cheese"
    }
    stub_document_type_inferer

    actions = stub('actions')
    GovukIndex::ElasticsearchProcessor.expects(:new).returns(actions)
    actions.expects(:delete)
    actions.expects(:commit).returns('items' => [{ 'delete' => { 'status' => 500 } }])

    Services.statsd_client.expects(:increment).with('govuk_index.sidekiq-consumed')
    Services.statsd_client.expects(:increment).with('govuk_index.elasticsearch.delete_error')
    Services.statsd_client.expects(:increment).with('govuk_index.sidekiq-retry')

    assert_raises(GovukIndex::ElasticsearchError) do
      GovukIndex::PublishingEventWorker.new.perform('routing.unpublish', payload)
    end
  end

  def test_does_not_raise_error_when_document_not_found_while_attempting_to_delete
    payload = {
      "base_path" => "/cheese",
      "document_type" => "substitute",
      "title" => "We love cheese"
    }
    stub_document_type_inferer

    actions = stub('actions')
    GovukIndex::ElasticsearchProcessor.expects(:new).returns(actions)
    actions.expects(:delete)
    actions.expects(:commit).returns('items' => [{ 'delete' => { 'status' => 404 } }])

    Services.statsd_client.expects(:increment).with('govuk_index.sidekiq-consumed')
    Services.statsd_client.expects(:increment).with('govuk_index.elasticsearch.already_deleted')
    GovukIndex::PublishingEventWorker.new.perform('routing.unpublish', payload)
  end

  def test_raise_error_if_elasticsearch_returns_multiple_responses
    payload = {
      "base_path" => "/cheese",
      "document_type" => "vanish",
      "title" => "We love cheese"
    }
    stub_document_type_inferer

    actions = stub('actions')
    GovukIndex::ElasticsearchProcessor.expects(:new).returns(actions)
    actions.expects(:delete)
    actions.expects(:commit).returns('items' => [{ 'index' => { 'status' => 200 } }, { 'delete' => { 'status' => 200 } }])

    Services.statsd_client.expects(:increment).with('govuk_index.sidekiq-consumed')
    Services.statsd_client.expects(:increment).with('govuk_index.elasticsearch.multiple_responses')
    Services.statsd_client.expects(:increment).with('govuk_index.sidekiq-retry')

    assert_raises(GovukIndex::MultipleMessagesInElasticsearchResponse) do
      GovukIndex::PublishingEventWorker.new.perform('routing.unpublish', payload)
    end
  end

  def test_notify_when_validation_error
    invalid_payload = {
      "document_type" => "help_page",
      "title" => "We love cheese"
    }

    GOVUK::Error.expects(:notify).with(
      instance_of(GovukIndex::ValidationError),
      parameters: { message_body: { 'document_type' => 'help_page', 'title' => 'We love cheese' } }
    )

    GovukIndex::PublishingEventWorker.new.perform('routing.key', invalid_payload)
  end

  def stub_document_type_inferer
    GovukIndex::DocumentTypeInferer.any_instance.stubs(:unpublishing_type).returns(true)
    GovukIndex::DocumentTypeInferer.any_instance.stubs(:type).returns('real_document_type')
  end
end
