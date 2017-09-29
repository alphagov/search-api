require 'spec_helper'

RSpec.describe GovukIndex::ElasticsearchProcessor do
  it "should_save_valid_document" do
    presenter = double(:presenter)
    allow(presenter).to receive(:identifier).and_return(
      _type: "help_page",
      _id: "/cheese"
    )
    allow(presenter).to receive(:document).and_return(
      link: "/cheese",
      title: "We love cheese"
    )

    client = double('client')
    allow(Services).to receive('elasticsearch').and_return(client)
    expect(client).to receive(:bulk).with(index: SearchConfig.instance.govuk_index_name, body: [{ index: presenter.identifier }, presenter.document])

    subject.save(presenter)
    subject.commit
  end

  it "should_delete_valid_document" do
    presenter = double(:presenter)
    allow(presenter).to receive(:identifier).and_return(
      _type: "help_page",
      _id: "/cheese"
    )
    allow(presenter).to receive(:document).and_return(
      link: "/cheese",
      title: "We love cheese"
    )

    client = double('client')
    allow(Services).to receive('elasticsearch').and_return(client)
    expect(client).to receive(:bulk).with(
      index: SearchConfig.instance.govuk_index_name,
      body: [
        {
          delete: presenter.identifier
        }
      ]
    )

    subject.delete(presenter)
    subject.commit
  end
end
