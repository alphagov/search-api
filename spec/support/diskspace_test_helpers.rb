require "spec_helper"

module DiskspaceTestHelpers
  def stub_diskspace_check
    es_source = ENV["ELASTICSEARCH_URI"] || "http://localhost:9200"
    stub_request(:any, "#{es_source}/_nodes/stats/fs?pretty=true")
    .to_return(
      status: 200,
      body: {
        "nodes": {
          "node": {
            "fs": {
              "total": {
                "total_in_bytes": 200,
                "available_in_bytes": 100,
              },
            },
          },
        },
      }.to_json,
      headers: {
        "Content-Type" => "application/json",
      },
    )
  end

  def stub_diskspace_fail_check
    es_source = ENV["ELASTICSEARCH_URI"] || "http://localhost:9200"
    stub_request(:any, "#{es_source}/_nodes/stats/fs?pretty=true")
    .to_return(
      status: 200,
      body: {
        "nodes": {
          "node": {
            "fs": {
              "total": {
                "total_in_bytes": 200,
                "available_in_bytes": 20,
              },
            },
          },
        },
      }.to_json,
      headers: {
        "Content-Type" => "application/json",
      },
    )
  end
end
