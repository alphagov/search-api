require "test_helper"
require 'govuk_index/elasticsearch_saver'
require 'support/test_index_helpers'

class ElasticsearchSaverTest < Minitest::Test
  def test_should_save_valid_document
    # TestIndexHelpers.setup_test_indexes

    presenter = stub(:presenter)
    presenter.stubs(:identifier).returns(
      _type: "cheddar",
      _id: "/cheese"
    )
    presenter.stubs(:document).returns(
      link: "/cheese",
      title: "We love cheese"
    )

    client = stub('client')
    Services.stubs('elasticsearch').returns(client)
    client.expects(:bulk).with(index: SearchConfig.instance.govuk_index_name, body: [{ index: presenter.identifier }, presenter.document])

    GovukIndex::ElasticsearchSaver.new.save(presenter)
  end
end
