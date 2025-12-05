require "spec_helper"

module ConnectivityTestHelpers
  def stub_connectivity_check
    es_source = ENV["ELASTICSEARCH_URI"] || "http://localhost:9200"
    stub_request(:get, "#{es_source}/_cluster/health")
      .to_return(
        status: 200,
        body: {
          "cluster_name": "A",
          "status": "green",
          "timed_out": false,
          "number_of_nodes": 1,
          "number_of_data_nodes": 1,
          "active_primary_shards": 1,
          "active_shards": 1,
          "relocating_shards": 0,
          "initializing_shards": 0,
          "unassigned_shards": 1,
          "delayed_unassigned_shards": 0,
          "number_of_pending_tasks": 0,
          "number_of_in_flight_fetch": 0,
          "task_max_waiting_in_queue_millis": 0,
          "active_shards_percent_as_number": 50.0,
        }.to_json,
        headers: {
          "Content-Type" => "application/json",
        },
      )
  end

  def stub_connectivity_fail_check
    es_source = ENV["ELASTICSEARCH_URI"] || "http://localhost:9200"
    stub_request(:get, "#{es_source}/_cluster/health")
      .to_return(
        status: 200,
        body: "",
        headers: {
          "Content-Type" => "application/json",
        },
      )
  end
end
