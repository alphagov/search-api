require "integration_test_helper"

class AmendmentTest < IntegrationTest

  def setup
    super
    disable_secondary_search
  end

  def test_should_amend_existing_document
    @primary_search.expects(:get).returns(sample_document)
    @primary_search.expects(:add).with() do |documents|
      assert_equal 1, documents.length
      assert_equal "New exciting title", documents[0].title
      sample_document_attributes.each_pair do |key, value|
        assert_equal(sample_document_attributes[key], value) unless key == :title
      end
    end

    post "/documents/%2Ffoobang", {title: "New exciting title"}
  end

  def test_should_fail_on_invalid_field
    @primary_search.expects(:get).returns(sample_document)
    @primary_search.expects(:add).never

    post "/documents/%2Ffoobang", {fish: "Trout"}

    assert_equal 403, last_response.status
    assert_equal "Unrecognised field 'fish'", last_response.body
  end

  def test_should_fail_on_json_post
    @primary_search.expects(:get).never
    @primary_search.expects(:add).never

    post(
      "/documents/%2Ffoobang",
      '{"title": "New title"}',
      {"CONTENT_TYPE" => "application/json"}
    )

    assert_equal 415, last_response.status
  end

  def test_should_refuse_to_update_link
    @primary_search.expects(:get).returns(sample_document)
    @primary_search.expects(:add).never

    post "/documents/%2Ffoobang", {link: "/somewhere-else"}

    assert_equal 403, last_response.status
  end

  def test_should_fail_to_amend_missing_document
    @primary_search.expects(:get).returns(nil)
    @primary_search.expects(:add).never

    post "/documents/%2Ffoobang", {title: "New exciting title"}

    assert_equal 404, last_response.status
  end

end
