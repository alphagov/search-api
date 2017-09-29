require 'spec_helper'

RSpec.describe GovukIndex::PublishingEventWorker do
  it "save_valid_message" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "help_page",
      "title" => "We love cheese"
    }

    actions = double('actions')
    expect(GovukIndex::ElasticsearchProcessor).to receive(:new).and_return(actions)
    expect(actions).to receive(:save)
    expect(actions).to receive(:commit).and_return('items' => [{ 'index' => { 'status' => 200 } }])

    expect(Services.statsd_client).to receive(:increment).with('govuk_index.sidekiq-consumed')
    expect(Services.statsd_client).to receive(:increment).with('govuk_index.elasticsearch.index')
    subject.perform('routing.key', payload)
  end

  it "delete_record_when_unpublishing_message_received" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "redirect",
      "title" => "We love cheese"
    }
    stub_document_type_inferer

    actions = double('actions')

    expect(GovukIndex::ElasticsearchProcessor).to receive(:new).and_return(actions)
    expect(actions).to receive(:delete)
    expect(actions).to receive(:commit).and_return('items' => [{ 'delete' => { 'status' => 200 } }])

    expect(Services.statsd_client).to receive(:increment).with('govuk_index.sidekiq-consumed')
    expect(Services.statsd_client).to receive(:increment).with('govuk_index.elasticsearch.delete')
    subject.perform('routing.unpublish', payload)
  end

  it "should_not_delete_withdrawn" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "help_page",
      "title" => "We love cheese",
      "withdrawn_notice" => {
        "explanation" => "<div class=\"govspeak\"><p>test 2</p>\n</div>",
        "withdrawn_at" => "2017-08-03T14:02:18Z"
      }
    }

    actions = double('actions')
    expect(GovukIndex::ElasticsearchProcessor).to receive(:new).and_return(actions)
    expect(actions).to receive(:save)
    expect(actions).to receive(:commit).and_return('items' => [{ 'index' => { 'status' => 200 } }])

    expect(Services.statsd_client).to receive(:increment).with('govuk_index.sidekiq-consumed')
    expect(Services.statsd_client).to receive(:increment).with('govuk_index.elasticsearch.index')

    subject.perform('routing.unpublish', payload)
  end

  it "raise_error_when_elasticsearch_update_error" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "gone",
      "title" => "We love cheese"
    }
    stub_document_type_inferer

    actions = double('actions')
    expect(GovukIndex::ElasticsearchProcessor).to receive(:new).and_return(actions)
    expect(actions).to receive(:delete)
    expect(actions).to receive(:commit).and_return('items' => [{ 'delete' => { 'status' => 500 } }])

    expect(Services.statsd_client).to receive(:increment).with('govuk_index.sidekiq-consumed')
    expect(Services.statsd_client).to receive(:increment).with('govuk_index.elasticsearch.delete_error')
    expect(Services.statsd_client).to receive(:increment).with('govuk_index.sidekiq-retry')

    expect {
      subject.perform('routing.unpublish', payload)
    }.to raise_error(GovukIndex::ElasticsearchError)
  end

  it "does_not_raise_error_when_document_not_found_while_attempting_to_delete" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "substitute",
      "title" => "We love cheese"
    }
    stub_document_type_inferer

    actions = double('actions')
    expect(GovukIndex::ElasticsearchProcessor).to receive(:new).and_return(actions)
    expect(actions).to receive(:delete)
    expect(actions).to receive(:commit).and_return('items' => [{ 'delete' => { 'status' => 404 } }])

    expect(Services.statsd_client).to receive(:increment).with('govuk_index.sidekiq-consumed')
    expect(Services.statsd_client).to receive(:increment).with('govuk_index.elasticsearch.already_deleted')
    subject.perform('routing.unpublish', payload)
  end

  it "raise_error_if_elasticsearch_returns_multiple_responses" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "vanish",
      "title" => "We love cheese"
    }
    stub_document_type_inferer

    actions = double('actions')
    expect(GovukIndex::ElasticsearchProcessor).to receive(:new).and_return(actions)
    expect(actions).to receive(:delete)
    expect(actions).to receive(:commit).and_return('items' => [{ 'index' => { 'status' => 200 } }, { 'delete' => { 'status' => 200 } }])

    expect(Services.statsd_client).to receive(:increment).with('govuk_index.sidekiq-consumed')
    expect(Services.statsd_client).to receive(:increment).with('govuk_index.elasticsearch.multiple_responses')
    expect(Services.statsd_client).to receive(:increment).with('govuk_index.sidekiq-retry')

    expect {
      subject.perform('routing.unpublish', payload)
    }.to raise_error(GovukIndex::MultipleMessagesInElasticsearchResponse)
  end

  it "notify_when_validation_error" do
    invalid_payload = {
      "document_type" => "help_page",
      "title" => "We love cheese"
    }

    expect(GovukError).to receive(:notify).with(
      instance_of(GovukIndex::ValidationError),
      extra: { message_body: { 'document_type' => 'help_page', 'title' => 'We love cheese' } }
    )

    subject.perform('routing.key', invalid_payload)
  end

  def stub_document_type_inferer
    allow_any_instance_of(GovukIndex::DocumentTypeInferer).to receive(:unpublishing_type?).and_return(true)
    allow_any_instance_of(GovukIndex::DocumentTypeInferer).to receive(:type).and_return('real_document_type')
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return(%w(real_document_type))
  end
end
