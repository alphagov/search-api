require 'test_helper'

class ElasticsearchProcessorTest < Minitest::Test
  def test_should_save_valid_document
    presenter = stub(:presenter)
    presenter.stubs(:identifier).returns(
      _type: "help_page",
      _id: "/cheese"
    )
    presenter.stubs(:document).returns(
      link: "/cheese",
      title: "We love cheese"
    )

    client = stub('client')
    Services.stubs('elasticsearch').returns(client)
    client.expects(:bulk).with(index: SearchConfig.instance.govuk_index_name, body: [{ index: presenter.identifier }, presenter.document])

    actions = GovukIndex::ElasticsearchProcessor.new
    actions.save(presenter)
    actions.commit
  end

  def test_should_delete_valid_document
    presenter = stub(:presenter)
    presenter.stubs(:identifier).returns(
      _type: "help_page",
      _id: "/cheese"
    )
    presenter.stubs(:document).returns(
      link: "/cheese",
      title: "We love cheese"
    )

    client = stub('client')
    Services.stubs('elasticsearch').returns(client)
    client.expects(:bulk).with(
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
