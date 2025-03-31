require "spec_helper"

RSpec.describe GovukIndex::PublishingEventMessageHandler do
  subject { described_class.new }

  before do
    allow(Index::ElasticsearchProcessor).to receive(:new).and_return(actions)
    @statsd_client = instance_double("Statsd", increment: nil)
    allow(Services).to receive(:statsd_client).and_return @statsd_client
  end

  let(:actions) { instance_double("actions") }

  context "when a single message is received" do
    it "will save a valid document" do
      payload = {
        "base_path" => "/cheese",
        "document_type" => "help_page",
        "title" => "We love cheese",
      }
      responses = [{ "items" => [{ "index" => { "status" => 200 } }] }]
      expect(actions).to receive(:save)
      expect(actions).to receive(:commit).and_return(responses)

      expect(@statsd_client).to receive(:increment).with("govuk_index.elasticsearch.index")

      subject.process([["routing.key", payload]])
    end

    context "when a message to unpublish the document is received" do
      it "will delete the document" do
        payload = {
          "base_path" => "/cheese",
          "document_type" => "redirect",
          "title" => "We love cheese",
        }
        stub_document_type_mapper
        responses = [{ "items" => [{ "delete" => { "status" => 200 } }] }]
        expect(actions).to receive(:delete)
        expect(actions).to receive(:commit).and_return(responses)

        expect(@statsd_client).to receive(:increment).with("govuk_index.elasticsearch.delete")

        subject.process([["routing.unpublish", payload]])
      end

      it "will not delete withdrawn documents" do
        payload = {
          "base_path" => "/cheese",
          "document_type" => "help_page",
          "title" => "We love cheese",
          "withdrawn_notice" => {
            "explanation" => "<div class=\"govspeak\"><p>test 2</p>\n</div>",
            "withdrawn_at" => "2017-08-03T14:02:18Z",
          },
        }
        responses = [{ "items" => [{ "index" => { "status" => 200 } }] }]
        expect(actions).to receive(:save)
        expect(actions).to receive(:commit).and_return(responses)

        expect(@statsd_client).to receive(:increment).with("govuk_index.elasticsearch.index")

        subject.process([["routing.unpublish", payload]])
      end

      it "will raise an error when elasticsearch returns a 500 status" do
        payload = {
          "base_path" => "/cheese",
          "document_type" => "gone",
          "title" => "We love cheese",
        }
        failure_response = [{ "items" => [{ "delete" => { "status" => 500 } }] }]
        stub_document_type_mapper
        expect(actions).to receive(:delete)
        expect(actions).to receive(:commit).and_return(failure_response)

        expect(@statsd_client).to receive(:increment).with("govuk_index.elasticsearch.delete_error")

        expect {
          subject.process([["routing.unpublish", payload]])
        }.to raise_error(GovukIndex::ElasticsearchRetryError)
      end

      it "will not raise an error when elasticsearch returns a 404 - not found" do
        payload = {
          "base_path" => "/cheese",
          "document_type" => "substitute",
          "title" => "We love cheese",
        }
        stub_document_type_mapper
        responses = [{ "items" => [{ "delete" => { "status" => 404 } }] }]
        expect(actions).to receive(:delete)
        expect(actions).to receive(:commit).and_return(responses)

        expect(@statsd_client).to receive(:increment).with("govuk_index.elasticsearch.already_deleted")

        subject.process([["routing.unpublish", payload]])
      end
    end

    context "when document type requires a basepath" do
      let(:actions) { Index::ElasticsearchProcessor.govuk }
      let(:payload) do
        {
          "document_type" => "help_page",
          "title" => "We love cheese",
        }
      end

      it "notify of a validation error for missing basepath" do
        expect(GovukError).to receive(:notify).with(
          instance_of(GovukIndex::NotIdentifiable),
          extra: {
            message_body: {
              "document_type" => "help_page",
              "title" => "We love cheese",
            },
          },
        )

        subject.process([["routing.key", payload]])
      end
    end

    context "when document type doesn't require a basepath" do
      let(:actions) { Index::ElasticsearchProcessor.govuk }
      let(:payload) do
        {
          "document_type" => "contact",
          "title" => "We love cheese",
        }
      end

      it "don't notify of a validation error for missing basepath" do
        expect(GovukError).not_to receive(:notify)

        subject.process([["routing.key", payload]])
      end
    end
  end

  context "when multiple messages are received" do
    let(:payload1) do
      {
        "base_path" => "/cheese",
        "document_type" => "help_page",
        "title" => "We love cheese",
      }
    end
    let(:payload2) do
      {
        "base_path" => "/cheese",
        "document_type" => "help_page",
        "title" => "We love cheese",
      }
    end
    let(:payload_delete) do
      {
        "base_path" => "/cheese",
        "document_type" => "gone",
        "title" => "We love cheese",
      }
    end
    let(:payload_withdrawal) do
      {
        "base_path" => "/cheese",
        "document_type" => "help_page",
        "title" => "We love cheese",
      }
    end

    it "can save multiple documents" do
      responses = [{
        "items" => [{ "index" => { "status" => 200 } }, { "index" => { "status" => 200 } }],
      }]
      expect(actions).to receive(:save).twice
      expect(actions).to receive(:commit).and_return(responses)

      expect(@statsd_client).to receive(:increment).with("govuk_index.elasticsearch.multiple_responses")
      expect(@statsd_client).to receive(:increment).with("govuk_index.elasticsearch.index").twice

      subject.process([["routing.key", payload1], ["routing.key", payload2]])
    end

    it "can save and delete documents in the same batch" do
      stub_document_type_mapper
      responses = [{ "items" => [{ "index" => { "status" => 200 } }, { "delete" => { "status" => 200 } }] }]
      expect(actions).to receive(:save)
      expect(actions).to receive(:delete)
      expect(actions).to receive(:commit).and_return(responses)
      expect(@statsd_client).to receive(:increment).with("govuk_index.elasticsearch.multiple_responses")
      expect(@statsd_client).to receive(:increment).with("govuk_index.elasticsearch.index")
      expect(@statsd_client).to receive(:increment).with("govuk_index.elasticsearch.delete")

      subject.process([["routing.key", payload1], ["routing.key", payload_delete]])
    end

    context "when all messages fail" do
      before do
        allow(actions).to receive(:save).twice
        allow(actions).to receive(:commit).and_return(
          [{ "items" => [{ "index" => { "status" => 500 } }, { "index" => { "status" => 500 } }] }],
        )
        allow(@statsd_client).to receive(:increment)
      end

      it "will reprocess the entire batch using ES retry mechanism" do
        expect {
          subject.process([["routing.key", payload1], ["routing.key", payload2]])
        }.to raise_error(GovukIndex::ElasticsearchRetryError)
      end

      it "will notify for each message that fails" do
        expect {
          subject.process([["routing.key", payload1], ["routing.key", payload2]])
        }.to raise_error(GovukIndex::ElasticsearchRetryError)
        expect(@statsd_client).to have_received(:increment).with("govuk_index.elasticsearch.index_error").twice
      end

      it "will notify that the batch failed" do
        expect {
          subject.process([["routing.key", payload1], ["routing.key", payload2]])
        }.to raise_error(GovukIndex::ElasticsearchRetryError)
      end
    end

    context "elasticsearch fails during processing for some messages" do
      before do
        allow(actions).to receive(:save).twice
        allow(actions).to receive(:commit).and_return(
          [{ "items" => [{ "index" => { "status" => 200 } }, { "index" => { "status" => 500 } }] }],
        )
        allow(@statsd_client).to receive(:increment)
        # allow(GovukIndex::PublishingEventjob).to receive(:perform_async)
      end

      it "will notify for each message that fails" do
        expect {
          subject.process([["routing.key", payload1], ["routing.key", payload2]])
        }.to raise_error(GovukIndex::ElasticsearchRetryError)
        expect(@statsd_client).to have_received(:increment).with("govuk_index.elasticsearch.index_error")
        expect(@statsd_client).to have_received(:increment).with("govuk_index.elasticsearch.index")
      end
    end

    it "raises an error is the number of response item does not match the number of actions requested" do
      allow(actions).to receive(:save).twice
      allow(actions).to receive(:commit).and_return(
        [{ "items" => [{ "index" => { "status" => 200 } }] }],
      )
      allow(@statsd_client).to receive(:increment)

      expect {
        subject.process([["routing.key", payload1], ["routing.key", payload2]])
      }.to raise_error(GovukIndex::ElasticsearchInvalidResponseItemCount, "received 1 expected 2")
    end
  end

  def stub_document_type_mapper
    allow_any_instance_of(GovukIndex::ElasticsearchDeletePresenter).to receive(:type).and_return("real_document_type")
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return("real_document_type" => :all)
  end
end
