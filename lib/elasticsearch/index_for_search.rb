require "rest-client"
require "json"
require "elasticsearch/client"

module Elasticsearch

  class IndexForSearch
    attr_reader :index_names, :schema

    # How long to wait between reads when streaming data from the elasticsearch server
    TIMEOUT_SECONDS = 5.0

    # How long to wait for a connection to the elasticsearch server
    OPEN_TIMEOUT_SECONDS = 5.0

    def initialize(base_uri, index_names, schema, search_config)
      @index_uri = base_uri + "#{CGI.escape(index_names.join(","))}/"
      @client = build_client
      @index_names = index_names
      @schema = schema
      @search_config = search_config
    end

    def raw_search(payload, type=nil)
      json_payload = payload.to_json
      logger.debug "Request payload: #{json_payload}"
      if type.nil?
        path = "_search"
      else
        path = "#{type}/_search"
      end
      JSON.parse(@client.get_with_payload(path, json_payload))
    end

    def msearch(bodies)
      header_json = "{}"
      payload = bodies.map { |body|
        "#{header_json}\n#{body.to_json}\n"
      }.join("")
      logger.debug "Request payload: #{payload}"
      path = "_msearch"
      JSON.parse(@client.get_with_payload(path, payload))
    end

    # `options` must have the following key:
    #   :fields - a list of field names to be included in the document
    def documents_by_format(format, options = {})
      batch_size = 500
      search_body = {query: {term: {format: format}}}
      search_body.merge!(fields: options[:fields])
      field_names = options[:fields]
      result_key = "fields"

      ScrollEnumerator.new(@client, search_body, batch_size) do |hit|
        Document.new(field_names, hit[result_key])
      end
    end

private
    def logger
      Logging.logger[self]
    end

    def build_client(options={})
      Client.new(
        @index_uri,
        timeout: options[:timeout] || TIMEOUT_SECONDS,
        open_timeout: options[:open_timeout] || OPEN_TIMEOUT_SECONDS
      )
    end
  end
end
