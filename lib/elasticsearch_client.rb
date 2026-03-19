class ElasticsearchClient
  class << self
    private :new

    def instance
      Cache.get("#{ElasticsearchClient}") do
        new
      end
    end
  end

  def es_version
    @es_version ||= Gem::Version.new(Services.elasticsearch.info.dig('version', 'number'))
  end

  def es7?
    return true if ENV["USE_ELASTICSEARCH_7"]
    return false if ENV["USE_ELASTICSEARCH_6"]
    es_version >= Gem::Version.new('7.0.0')
  end

  def get(params, client = Services.elasticsearch)
    compatible_params = es7? ? params : params.merge(type: "_all")
    client.get(compatible_params)
  end

  def get_from_index(id, index, client = Services.elasticsearch)
    compatible_params = es7? ? {} : { type: "_all" }
    client.get({index:, id:}.merge(compatible_params))
  end

  # Payload to index documents using the `_bulk` endpoint
  #
  # The format is as follows:
  #
  #   {"index": {"_type": "generic-document", "_id": "/bank-holidays"}}
  #   { <document source> }
  #   {"index": {"_type": "generic-document", "_id": "/something-else"}}
  #   { <document source> }
  #
  # See <http://www.elasticsearch.org/guide/reference/api/bulk/>
  def bulk(payload, index, client = Services.elasticsearch)
    body = compatible_bulk_input(payload)
    client.bulk({index:, body: })
  end

  BULK_OPERATIONS = %w[delete index create update].freeze

  def compatible_bulk_input(payload)
    return payload if es7?

    payload = payload.dup
    [].tap do |result|
      until payload.empty?
        action = payload.shift.deep_stringify_keys
        key = BULK_OPERATIONS.find { |k| action.key?(k) }
        raise ArgumentError, "Invalid bulk action in payload: #{action.keys}" unless key

        action[key]["_type"] = "generic-document"
        result << action
        result << payload.shift unless key == "delete"
      end
    end
  end

  def index(id, atts, index, params={}, client = Services.elasticsearch)
    compatible_params = es7? ? {} : { type: "generic-document" }
    client.index({index:, id:, body: atts}.merge(params).merge(compatible_params))
  end

  def create_index(index_name, index_payload, client = Services.elasticsearch)
    client.indices.create(
      index: index_name,
      body: index_payload,
    )
  end

  def compatible_mappings(properties)
    return { "properties" => properties } if es7?

    { "generic-document" => { "properties" => properties } }
  end
end