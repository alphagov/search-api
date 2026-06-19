require "spec_helper"

RSpec.describe SearchIndices::Index do
  let(:base_uri) { "http://example.com:9200" }

  it "syncs mappings to elasticsearch" do
    mappings = {
      "generic-document" => {
        "properties" => {
          "new-field" => { "type": "text" },
        },
      },
    }
    stub = stub_request(:put, %r{#{base_uri}/govuk-abc/_mapping/generic-document})
             .with(body: mappings["generic-document"])
             .to_return({
               status: 200,
               body: { "ok" => true, "acknowledged" => true }.to_json,
               headers: { "Content-Type" => "application/json" },
             })

    index = SearchIndices::Index.new(base_uri, "govuk-abc", "govuk", SearchConfig.default_instance)

    errors = index.sync_mappings(mappings["generic-document"])

    assert_requested stub
    expect(errors).to be_empty
  end

  it "syncs mappings to elasticsearch and returns any failures" do
    mappings = {
      "generic-document" => {
        "properties" => {
          "new-field" => { "type": "text" },
        },
      },
    }
    error_body = { "error" => {
      "type" => "illegal_argument_exception",
      "reason" => "invalid mapping",
    } }.to_json

    stub = stub_request(:put, %r{#{base_uri}/govuk-abc/_mapping/generic-document})
      .with(body: mappings["generic-document"])
             .to_return({
               status: 400,
               body: error_body,
               headers: { "Content-Type" => "application/json" },
             })

    index = SearchIndices::Index.new(base_uri, "govuk-abc", "govuk", SearchConfig.default_instance)

    errors = index.sync_mappings(mappings["generic-document"])

    assert_requested stub
    expect(errors).not_to be_empty
    expect(Elasticsearch::Transport::Transport::Errors::BadRequest.new("[400] #{error_body}").message).to eq(errors["generic-document"].message)
  end
end
