require "spec_helper"

RSpec.describe GovukIndex::PublishingEventMessageHandler do
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

      described_class.call("routing.key", payload)
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

        described_class.call("routing.unpublish", payload)
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

        described_class.call("routing.unpublish", payload)
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
          described_class.call("routing.unpublish", payload)
        }.to raise_error(described_class::ElasticsearchRetryError)
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

        described_class.call("routing.unpublish", payload)
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

        described_class.call("routing.key", payload)
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

        described_class.call("routing.key", payload)
      end
    end
  end

  def stub_document_type_mapper
    allow_any_instance_of(GovukIndex::ElasticsearchDeletePresenter).to receive(:type).and_return("real_document_type")
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return("real_document_type" => :all)
  end
end
