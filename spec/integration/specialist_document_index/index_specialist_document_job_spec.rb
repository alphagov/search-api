require "spec_helper"

RSpec.describe SpecialistDocumentIndex::IndexSpecialistDocumentJob do
  subject(:job) { described_class.new }

  before do
    allow(Index::ElasticsearchProcessor).to receive(:new).and_return(processor)
    @statsd_client = instance_double("Statsd", increment: nil)
    allow(Services).to receive(:statsd_client).and_return @statsd_client
  end

  let(:processor) { instance_double("processor") }
  let(:presenter) { instance_double("presenter") }

  it "indexes documents and records metrics" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "cma_case",
      "title" => "We love cheese",
    }
    responses = [{ "items" => [{ "index" => { "status" => 200 } }] }]

    presenter = instance_double("presenter")
    allow(SpecialistDocumentIndex::DocumentPresenter).to receive(:new).with(payload).and_return(presenter)

    expect(processor).to receive(:save).with(presenter)
    expect(processor).to receive(:commit).and_return(responses)

    expect(@statsd_client).to receive(:increment).with("specialist_document_index.sidekiq-consumed")
    expect(@statsd_client).to receive(:increment).with("specialist_document_index.elasticsearch.index")

    job.perform(payload)
  end
end
