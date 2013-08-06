require "integration_test_helper"

class AmendmentTest < IntegrationTest
  def test_should_amend_existing_document
    index = stub_index
    index.expects(:amend)
      .with("/foobang", "title" => "New exciting title")
      .returns(true)
    post "/documents/%2Ffoobang", {title: "New exciting title"}
  end

  def test_should_fail_on_invalid_field
    index = stub_index
    error = ArgumentError.new( "Unrecognised field 'fish'")
    index.expects(:amend).with("/foobang", "fish" => "Trout").raises(error)

    post "/documents/%2Ffoobang", {fish: "Trout"}

    assert_equal 403, last_response.status
    assert_equal "Unrecognised field 'fish'", last_response.body
  end

  def test_should_fail_on_json_post
    index = stub_index
    index.expects(:amend).never

    post(
      "/documents/%2Ffoobang",
      '{"title": "New title"}',
      {"CONTENT_TYPE" => "application/json"}
    )

    assert_equal 415, last_response.status
  end

  def test_should_queue_amendments_when_configured
    app.stubs(:enable_queue).returns(true)
    stub_index.expects(:amend_queued).with("/foobang", "title" => "New title")

    post "/documents/%2Ffoobang", {title: "New title"}

    assert_equal 202, last_response.status
  end

  def test_should_refuse_to_update_link
    index = stub_index
    index.expects(:amend)
      .with("/foobang", "link" => "/somewhere-else")
      .raises(ArgumentError.new("Cannot change document links"))

    post "/documents/%2Ffoobang", {link: "/somewhere-else"}

    assert_equal 403, last_response.status
  end

  def test_should_fail_to_amend_missing_document
    index = stub_index
    index.expects(:amend)
      .with("/foobang", anything)
      .raises(Elasticsearch::DocumentNotFound)

    post "/documents/%2Ffoobang", {title: "New exciting title"}

    assert_equal 404, last_response.status
  end
end
