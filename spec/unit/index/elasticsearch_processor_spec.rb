require "spec_helper"

RSpec.describe Index::ElasticsearchProcessor do
  subject { described_class.govuk }
  let(:cluster_count) { Clusters.count }

  it "should save valid document" do
    presenter = double(:presenter)
    allow(presenter).to receive(:identifier).and_return(
      _type: "help_page",
      _id: "/cheese"
    )
    allow(presenter).to receive(:document).and_return(
      link: "/cheese",
      title: "We love cheese"
    )

    client = double("client")
    allow(Services).to receive("elasticsearch").and_return(client)
    # rubocop:disable RSpec/MessageSpies
    expect(client).to receive(:bulk).exactly(cluster_count).times.with(index: SearchConfig.govuk_index_name, body: [{ index: presenter.identifier }, presenter.document])
    # rubocop:enable RSpec/MessageSpies
    subject.save(presenter)
    subject.commit
  end

  it "should delete valid document" do
    presenter = double(:presenter)
    allow(presenter).to receive(:identifier).and_return(
      _type: "help_page",
      _id: "/cheese"
    )
    allow(presenter).to receive(:document).and_return(
      link: "/cheese",
      title: "We love cheese"
    )

    client = double("client")
    allow(Services).to receive("elasticsearch").and_return(client)
    # rubocop:disable RSpec/MessageSpies
    expect(client).to receive(:bulk).exactly(cluster_count).times.with(
      index: SearchConfig.govuk_index_name,
      body: [
        {
          delete: presenter.identifier
        }
      ]
    )
    # rubocop:enable RSpec/MessageSpies

    subject.delete(presenter)
    subject.commit
  end
end
