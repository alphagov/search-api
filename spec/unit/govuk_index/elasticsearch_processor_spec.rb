require 'spec_helper'

RSpec.describe 'ElasticsearchProcessorTest' do
  it "should_save_valid_document" do
    presenter = double(:presenter)
    presenter.stub(:identifier).and_return(
      _type: "help_page",
      _id: "/cheese"
    )
    presenter.stub(:document).and_return(
      link: "/cheese",
      title: "We love cheese"
    )

    client = double('client')
    Services.stub('elasticsearch').and_return(client)
    expect(client).to receive(:bulk).with(index: SearchConfig.instance.govuk_index_name, body: [{ index: presenter.identifier }, presenter.document])

    actions = GovukIndex::ElasticsearchProcessor.new
    actions.save(presenter)
    actions.commit
  end

  it "should_delete_valid_document" do
    presenter = double(:presenter)
    presenter.stub(:identifier).and_return(
      _type: "help_page",
      _id: "/cheese"
    )
    presenter.stub(:document).and_return(
      link: "/cheese",
      title: "We love cheese"
    )

    client = double('client')
    Services.stub('elasticsearch').and_return(client)
    expect(client).to receive(:bulk).with(
      index: SearchConfig.instance.govuk_index_name,
      body: [
        {
          delete: presenter.identifier
        }
      ]
    )

    actions = GovukIndex::ElasticsearchProcessor.new
    actions.delete(presenter)
    actions.commit
  end
end
