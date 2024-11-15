require "spec_helper"

RSpec.describe SpecialistDocumentIndex::IndexSpecialistDocumentJob do
  subject(:job) { described_class.new }

  before do
    allow(Index::ElasticsearchProcessor).to receive(:new).and_return(actions)
    @statsd_client = instance_double("Statsd", increment: nil)
    allow(Services).to receive(:statsd_client).and_return @statsd_client
  end

  it "will save a valid specialist document" do


    allow(Index::ElasticsearchProcessor).to receive(:new).and_return(actions)

    payload = {
      "base_path" => "/cma-case/test-case",
      "document_type" => "cma_case",
      "title" => "Test Case",
    }
    responses = [{ "items" => [{ "index" => { "status" => 200 } }] }]
    expect(actions).to receive(:save)
    expect(actions).to receive(:commit).and_return(responses)

    expect(@statsd_client).to receive(:increment).with("govuk_index.sidekiq-consumed")
    expect(@statsd_client).to receive(:increment).with("govuk_index.elasticsearch.index")

    job.perform({ payload })
  end
end
