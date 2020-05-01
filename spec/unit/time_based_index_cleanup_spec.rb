require "spec_helper"

RSpec.describe SearchIndices::IndexGroup do
  ELASTICSEARCH_OK = {
    status: 200,
    body: { "ok" => true, "acknowledged" => true }.to_json,
    headers: { "Content-Type" => "application/json" },
  }.freeze

  BASE_URI = "http://example.com:9200".freeze

  before do
    @schema = SearchConfig.default_instance.search_server.schema
    @server = SearchIndices::SearchServer.new(
      BASE_URI,
      @schema,
      %w[government custom],
      "govuk",
      %w[government],
      SearchConfig.default_instance,
    )
  end

  # Will error if we try to call the delete due to lack of stub
  it "timed clean with only one live index does not delete the index" do
    live_name = "test-2012-03-01t12:00:00z-12345678-1234-1234-1234-123456789012"

    stub_request(:get, %r{#{BASE_URI}/test\*\?.*})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          live_name => { "aliases" => { "test" => {} } },
        }.to_json,
      )

    expected_response_body = {
      "hits" => {
        "hits" => {
          live_name => { "updated_at" => "1" },
        },
      },
    }

    stub_request(:get, %r{#{BASE_URI}/test(.*?)/_search})
      .with(
        body: expected_timed_delete_body,
      ).to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: expected_response_body.to_json,
      )

    @server.index_group("test").timed_clean(0)
  end

  # Will error if we try to call the delete due to lack of stub
  it "timed clean with only one dead index does not delete the index" do
    dead_name = "test-2012-03-01t12:00:00z-12345678-1234-1234-1234-123456789012"

    stub_request(:get, %r{#{BASE_URI}/test\*\?.*})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          dead_name => { "aliases" => {} },
        }.to_json,
      )

    expected_response_body = {
      "hits" => {
        "hits" => {
          dead_name => { "updated_at" => "1" },
        },
      },
    }

    stub_request(:get, %r{#{BASE_URI}/test(.*?)/_search})
      .with(
        body: expected_timed_delete_body,
      ).to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: expected_response_body.to_json,
      )

    @server.index_group("test").timed_clean(0)
  end

  # Will error if we try to call the delete due to lack of stub
  it "timed clean with one live and one dead index does not delete either index" do
    live_name = "test-2012-03-01t12:00:00z-12345678-1234-1234-1234-123456789012"
    dead_name = "test-2012-02-01t12:00:00z-87654321-4321-4321-4321-210987654321"

    stub_request(:get, %r{#{BASE_URI}/test\*\?.*})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          live_name => { "aliases" => { "test" => {} } },
          dead_name => { "aliases" => {} },
        }.to_json,
      )

    expected_response_body = {
      "hits" => {
        "hits" => {
          live_name => { "updated_at" => "1" },
          dead_name => { "updated_at" => "2" },
        },
      },
    }

    stub_request(:get, %r{#{BASE_URI}/test(.*?)/_search})
      .with(
        body: expected_timed_delete_body,
      ).to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: expected_response_body.to_json,
      )

    @server.index_group("test").timed_clean(0)
  end

  # Will error if we try to delete anything that is not the oldest index due to lack of stub
  it "timed clean with one live and two dead indexes only deletes oldest dead index" do
    live_name = "test-2012-03-01t12:00:00z-12345678-1234-1234-1234-123456789012"
    dead_name = "test-2012-02-01t12:00:00z-87654321-4321-4321-4321-210987654321"
    dead_name_two = "test-2012-01-01t12:00:00z-87654321-4321-4321-4321-210987654321"

    stub_request(:get, %r{#{BASE_URI}/test\*\?.*})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          live_name => { "aliases" => { "test" => {} } },
          dead_name => { "aliases" => {} },
          dead_name_two => { "aliases" => {} },
        }.to_json,
      )

    expected_response_body = {
      "hits" => {
        "hits" => {
          live_name => { "updated_at" => "1" },
          dead_name => { "updated_at" => "2" },
          dead_name_two => { "updated_at" => "3" },
        },
      },
    }

    stub_request(:get, %r{#{BASE_URI}/test(.*?)/_search})
      .with(
        body: expected_timed_delete_body,
      ).to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: expected_response_body.to_json,
      )

    delete_stub = stub_request(:delete, "#{BASE_URI}/#{dead_name_two}")
      .to_return(ELASTICSEARCH_OK)

    @server.index_group("test").timed_clean(0)

    assert_requested delete_stub
  end

  def expected_timed_delete_body
    {
      "_source" => "updated_at",
      "size" => 1,
      "sort" => [
        {
          "updated_at" =>
          {
            "order" => "desc",
            "unmapped_type" => "date",
          },
        },
      ],
    }
  end
end
