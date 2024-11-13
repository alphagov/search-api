require "spec_helper"

RSpec.describe SearchIndices::IndexGroup do
  let(:elasticsearch_ok) do
    {
      status: 200,
      body: { "ok" => true, "acknowledged" => true }.to_json,
      headers: { "Content-Type" => "application/json" },
    }
  end

  let(:base_uri) { "http://example.com:9200" }

  before do
    @schema = SearchConfig.default_instance.search_server.schema
    @server = SearchIndices::SearchServer.new(
      base_uri,
      @schema,
      SearchConfig.default_instance,
      SearchConfig.all_index_names,
    )
  end

  it "create index" do
    expected_body = {
      "settings" => @schema.elasticsearch_settings("government"),
      "mappings" => @schema.elasticsearch_mappings("government"),
    }.to_json
    stub = stub_request(:put, %r{#{base_uri}/government-.*})
      .with(body: expected_body)
      .to_return(elasticsearch_ok)
    index = @server.index_group("government").create_index

    assert_requested(stub)
    expect(index).to be_a SearchIndices::Index
    expect(index.index_name).to match(/^government-/)
  end

  it "switch index with no existing alias" do
    new_index = double("New index", index_name: "test-new")
    get_stub = stub_request(:get, "#{base_uri}/_alias")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          "test-new" => { "aliases" => {} },
        }.to_json,
      )
    expected_body = {
      "actions" => [
        { "add" => { "index" => "test-new", "alias" => "test" } },
      ],
    }.to_json
    post_stub = stub_request(:post, "#{base_uri}/_aliases")
      .with(
        body: expected_body,
        headers: { "Content-Type" => "application/json" },
      )
      .to_return(elasticsearch_ok)

    @server.index_group("test").switch_to(new_index)

    assert_requested(get_stub)
    assert_requested(post_stub)
  end

  it "switch index with existing alias" do
    new_index = double("New index", index_name: "test-new")
    get_stub = stub_request(:get, "#{base_uri}/_alias")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          "test-old" => { "aliases" => { "test" => {} } },
          "test-new" => { "aliases" => {} },
        }.to_json,
      )

    expected_body = {
      "actions" => [
        { "remove" => { "index" => "test-old", "alias" => "test" } },
        { "add" => { "index" => "test-new", "alias" => "test" } },
      ],
    }.to_json
    post_stub = stub_request(:post, "#{base_uri}/_aliases")
      .with(body: expected_body)
      .to_return(elasticsearch_ok)

    @server.index_group("test").switch_to(new_index)

    assert_requested(get_stub)
    assert_requested(post_stub)
  end

  it "switch index with multiple existing aliases" do
    # Not expecting the system to get into this state, but it should cope
    new_index = double("New index", index_name: "test-new")
    get_stub = stub_request(:get, "#{base_uri}/_alias")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          "test-old" => { "aliases" => { "test" => {} } },
          "test-old2" => { "aliases" => { "test" => {} } },
          "test-new" => { "aliases" => {} },
        }.to_json,
      )

    expected_body = {
      "actions" => [
        { "remove" => { "index" => "test-old", "alias" => "test" } },
        { "remove" => { "index" => "test-old2", "alias" => "test" } },
        { "add" => { "index" => "test-new", "alias" => "test" } },
      ],
    }.to_json
    post_stub = stub_request(:post, "#{base_uri}/_aliases")
      .with(body: expected_body)
      .to_return(elasticsearch_ok)

    @server.index_group("test").switch_to(new_index)

    assert_requested(get_stub)
    assert_requested(post_stub)
  end

  it "switch index with existing real index" do
    new_index = double("New index", index_name: "test-new")
    stub_request(:get, "#{base_uri}/_alias")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          "test" => { "aliases" => {} },
        }.to_json,
      )

    expect {
      @server.index_group("test").switch_to(new_index)
    }.to raise_error(RuntimeError)
  end

  it "index names with no indices" do
    stub_request(:get, %r{#{base_uri}/test\*\?.*})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {}.to_json,
      )

    expect(@server.index_group("test").index_names).to eq([])
  end

  it "index names with index" do
    index_name = "test-2012-03-01t12:00:00z-12345678-1234-1234-1234-123456789012"
    stub_request(:get, %r{#{base_uri}/test\*\?.*})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          index_name => { "aliases" => { "test" => {} } },
        }.to_json,
      )

    expect(@server.index_group("test").index_names).to eq([index_name])
  end

  it "index names with other groups" do
    this_name = "test-2012-03-01t12:00:00z-12345678-1234-1234-1234-123456789012"
    other_name = "fish-2012-03-01t12:00:00z-87654321-4321-4321-4321-210987654321"

    stub_request(:get, %r{#{base_uri}/test\*\?.*})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          this_name => { "aliases" => {} },
          other_name => { "aliases" => {} },
        }.to_json,
      )

    expect(@server.index_group("test").index_names).to eq([this_name])
  end

  it "clean with no indices" do
    stub_request(:get, %r{#{base_uri}/test\*\?.*})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {}.to_json,
      )

    @server.index_group("test").clean
  end

  it "clean with dead index" do
    index_name = "test-2012-03-01t12:00:00z-12345678-1234-1234-1234-123456789012"
    stub_request(:get, %r{#{base_uri}/test\*\?.*})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          index_name => { "aliases" => {} },
        }.to_json,
      )

    delete_stub = stub_request(:delete, "#{base_uri}/#{index_name}")
      .to_return(elasticsearch_ok)

    @server.index_group("test").clean

    assert_requested delete_stub
  end

  it "clean with live index" do
    index_name = "test-2012-03-01t12:00:00z-12345678-1234-1234-1234-123456789012"
    stub_request(:get, %r{#{base_uri}/test\*\?.*})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          index_name => { "aliases" => { "test" => {} } },
        }.to_json,
      )

    @server.index_group("test").clean
  end

  it "clean with multiple indices" do
    index_names = [
      "test-2012-03-01t12:00:00z-12345678-1234-1234-1234-123456789012",
      "test-2012-03-01t12:00:00z-abcdefab-abcd-abcd-abcd-abcdefabcdef",
    ]
    stub_request(:get, %r{#{base_uri}/test\*\?.*})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          index_names[0] => { "aliases" => {} },
          index_names[1] => { "aliases" => {} },
        }.to_json,
      )

    delete_stubs = index_names.map do |index_name|
      stub_request(:delete, "#{base_uri}/#{index_name}")
        .to_return(elasticsearch_ok)
    end

    @server.index_group("test").clean

    delete_stubs.each { |delete_stub| assert_requested delete_stub }
  end

  it "clean with live and dead indices" do
    live_name = "test-2012-03-01t12:00:00z-12345678-1234-1234-1234-123456789012"
    dead_name = "test-2012-03-01t12:00:00z-87654321-4321-4321-4321-210987654321"

    stub_request(:get, %r{#{base_uri}/test\*\?.*})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          live_name => { "aliases" => { "test" => {} } },
          dead_name => { "aliases" => {} },
        }.to_json,
      )

    delete_stub = stub_request(:delete, "#{base_uri}/#{dead_name}")
      .to_return(elasticsearch_ok)

    @server.index_group("test").clean

    assert_requested delete_stub
  end

  it "clean with other alias" do
    # If there's an alias we don't know about, that should save the index
    index_name = "test-2012-03-01t12:00:00z-12345678-1234-1234-1234-123456789012"
    stub_request(:get, %r{#{base_uri}/test\*\?.*})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          index_name => { "aliases" => { "something_else" => {} } },
        }.to_json,
      )

    @server.index_group("test").clean
  end

  it "clean with other groups" do
    # Check we don't go around deleting index from other groups
    this_name = "test-2012-03-01t12:00:00z-12345678-1234-1234-1234-123456789012"
    other_name = "fish-2012-03-01t12:00:00z-87654321-4321-4321-4321-210987654321"

    stub_request(:get, %r{#{base_uri}/test\*\?.*})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          this_name => { "aliases" => {} },
          other_name => { "aliases" => {} },
        }.to_json,
      )

    delete_stub = stub_request(:delete, "#{base_uri}/#{this_name}")
      .to_return(elasticsearch_ok)

    @server.index_group("test").clean

    assert_requested delete_stub
  end
end
