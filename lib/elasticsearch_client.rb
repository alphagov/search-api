# frozen_string_literal: true

module ElasticsearchClient
  class Error < StandardError; end
  class IndexLocked < StandardError; end

  def self.analyze(query:, index_name:, analyzer:, client: Services.elasticsearch)
    client.indices.analyze(
      index: index_name,
      body: {
        text: query,
        analyzer:,
      })
  end

  def self.bulk(body:, index_name:, client: Services.elasticsearch)
    raise "does not accept _type" if body.any? { |h| h.key?(:_type) || h.key?("_type") }

    client.bulk(index: index_name, body: _compatible_bulk_input(body))
  end

  BULK_OPERATIONS = %w[delete index create update].freeze

  def self._compatible_bulk_input(body)
    body = body.dup
    [].tap do |result|
      until body.empty?
        action = body.shift.deep_stringify_keys
        key = BULK_OPERATIONS.find { |k| action.key?(k) }
        raise ArgumentError, "Invalid bulk action in body: #{action.keys}" unless key

        action[key]["_type"] = "generic-document"
        result << action
        result << body.shift unless key == "delete"
      end
    end
  end

  def self.refresh_index(index_name:, client: Services.elasticsearch)
    client.indices.refresh(index: index_name)
  end

  def self.delete(index_name:, id:, client: Services.elasticsearch)
    client.delete(index: index_name, type: "generic-document", id:)
  rescue Elasticsearch::Transport::Transport::Errors::NotFound
    # We are fine with trying to delete deleted documents.
    true
  rescue Elasticsearch::Transport::Transport::Errors::Forbidden => e
    if e.message =~ %r{\[FORBIDDEN/[^/]+/index read-only}
      raise IndexLocked
    else
      raise
    end
  end

  def self.get_by_id(index_name:, id:, client: Services.elasticsearch)
    client.get(index: index_name, type: "_all", id:)
  rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
    raise ElasticsearchClient::Error, e.message
  end

  def self.get_alias(index_name: nil, client: Services.elasticsearch)
    client.indices.get_alias(index: index_name, expand_wildcards: ["open", "closed"],)
  rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
    raise ElasticsearchClient::Error, e.message
  end

  def self.set_alias(actions:, client: Services.elasticsearch)
    client.indices.update_aliases(body: { "actions" => actions })
  end

  def self.index_recovery(index_name:, client: Services.elasticsearch)
    client.indices.recovery(index: index_name)
  end

  def self.lock_index(index_name:, client: Services.elasticsearch)
    client.indices.put_settings(index: index_name, body:  { "index" => { "blocks" => { "read_only_allow_delete" => true } } })
  end

  def self.unlock_index(index_name:, client: Services.elasticsearch)
    client.indices.put_settings(index: index_name, body: { "index" => { "blocks" => { "read_only_allow_delete" => false } } })
  end

  def self.search(body:,
                  index_name:,
                  search_type: nil,
                  version: nil,
                  scroll: nil,
                  size: nil,
                  client: Services.elasticsearch)

    params = {
      index: index_name,
      body:,
      scroll: scroll,
      size: size,
      version: version,
      search_type: search_type,
    }.compact

    client.search(**params)
  end

  def self.scroll(scroll_id:, scroll: "1m", client: Services.elasticsearch)
    client.scroll(scroll_id:, scroll:)
  end

  def self.put_mapping(index_name:, mapping:, client: Services.elasticsearch)
    client.indices.put_mapping(index: index_name, type: "generic-document", body: mapping)
  rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
    raise ElasticsearchClient::Error, e.message
  end

  def self.create_index(index_name:, body:, client: Services.elasticsearch)
    client.indices.create(index: index_name, body:)
  end

  def self.delete_index(index_name:, client: Services.elasticsearch)
    client.indices.delete(index: index_name)
  end

  def self.health(client: Services.elasticsearch)
    client.cluster.health
  end

  def self.nodes_stats(metric: "fs", client: Services.elasticsearch)
    client.nodes.stats(metric:)
  end

  def self.update(index_name:, id:, client:, body:)
    client.update(index: index_name, id:, type: "generic-document", body:)
  end

  def self.rank_eval(requests:, metric:, indices: "*", client: Services.elasticsearch)
    client.rank_eval(index: indices, body: { requests:, metric: })
  end
end
