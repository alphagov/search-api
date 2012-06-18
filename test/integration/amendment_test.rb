# encoding: utf-8
require_relative "integration_helper"

class AmendmentTest < IntegrationTest

  def test_should_amend_existing_document
    @solr.expects(:get).returns(sample_document)
    @solr.expects(:add).with() do |documents|
      assert_equal 1, documents.length
      assert_equal "New exciting title", documents[0].title
      sample_document_attributes.each_pair do |key, value|
        assert_equal(sample_document_attributes[key], value) unless key == :title
      end
    end
    post "/documents/%2Ffoobang", {title: "New exciting title"}
  end

  def test_should_fail_on_invalid_parameter
    @solr.expects(:get).returns(sample_document)
    @solr.expects(:add).never
    post "/documents/%2Ffoobang", {fish: "Trout"}
    assert_equal 500, last_response.status
  end

  def test_should_fail_to_amend_missing_document
    @solr.expects(:get).returns(nil)
    @solr.expects(:add).never
    post "/documents/%2Ffoobang", {title: "New exciting title"}
    assert_equal 404, last_response.status
  end

end
