require "spec_helper"

RSpec.describe Index::ElasticsearchProcessor do
  subject { described_class.govuk }

  let(:cluster_count) { Clusters.count }

  it "saves valid document" do
    presenter = double(:presenter)
    allow(presenter).to receive(:identifier).and_return(
      _type: "help_page",
      _id: "/cheese",
    )
    allow(presenter).to receive(:document).and_return(
      link: "/cheese",
      title: "We love cheese",
    )

    client = double("client")
    allow(Services).to receive("elasticsearch").and_return(client)
    expect(client).to receive(:bulk).exactly(cluster_count).times.with({
      index: SearchConfig.govuk_index_name,
      body: [
        { index: presenter.identifier }, presenter.document
      ],
    })

    subject.save(presenter)
    subject.commit
  end

  it "deletes valid document" do
    presenter = double(:presenter)
    allow(presenter).to receive(:identifier).and_return(
      _type: "help_page",
      _id: "/cheese",
    )
    allow(presenter).to receive(:document).and_return(
      link: "/cheese",
      title: "We love cheese",
    )

    client = double("client")
    allow(Services).to receive("elasticsearch").and_return(client)
    expect(client).to receive(:bulk).exactly(cluster_count).times.with({
      index: SearchConfig.govuk_index_name,
      body: [
        {
          delete: presenter.identifier,
        },
      ],
    })

    subject.delete(presenter)
    subject.commit
  end
end
