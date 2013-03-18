require "logging"

module Elasticsearch
  class Client

    # Sub-paths almost certainly shouldn't start with leading slashes,
    # since this will make the request relative to the server root
    SAFE_ABSOLUTE_PATHS = ["/_bulk", "/_status", "/_aliases", "/_search/scroll"]

    def initialize(base_uri)
      @base_uri = base_uri
      @error_log_level = :error
    end

    # Forward on HTTP request methods, intercepting and resolving URLs
    [:get, :post, :put, :head, :delete].each do |method_name|
      define_method method_name do |sub_path, *args|
        full_url = url_for(sub_path)
        logger.debug "Sending #{method_name.upcase} request to #{full_url}"
        args.each_with_index do |argument, index|
          logger.debug "Argument #{index + 1}: #{argument.inspect}"
        end
        recording_elastic_error do
          logging_exception_body do
            RestClient.send(method_name, full_url, *args)
          end
        end
      end
    end

    # RestClient doesn't natively support sending payloads with these request
    # methods, but elasticsearch requires them for certain operations
    [:get, :delete].each do |method_name|
      define_method "#{method_name}_with_payload" do |sub_path, payload|
        request(method_name, sub_path, payload)
      end
    end

    # Execute the given block while recording RestClient errors at a different
    # log level.
    #
    # Sometimes, a 500 error from elasticsearch doesn't mean something has gone
    # wrong, such as when any of the shards in a scrolling query have run out
    # of results.
    def with_error_log_level(level, &block)
      previous_level, @error_log_level = @error_log_level, level
      return yield
    ensure
      @error_log_level = previous_level
    end

  private
    def logger
      Logging.logger[self]
    end

    def url_for(sub_path)
      if sub_path.is_a? URI
        sub_path = sub_path.to_s
      end
      if sub_path.start_with? "/"
        path_without_query = sub_path.split("?")[0]
        unless SAFE_ABSOLUTE_PATHS.include? path_without_query
          logger.error "Request sub-path '#{sub_path}' has a leading slash"
          raise ArgumentError, "Only whitelisted absolute paths are allowed"
        end
      end

      # Addition on URLs does relative resolution
      (@base_uri + sub_path).to_s
    end

    def recording_elastic_error(&block)
      yield
    rescue Errno::ECONNREFUSED, Timeout::Error, SocketError
      Rummager.statsd.increment("elasticsearcherror")
      raise
    end

    def logging_exception_body(&block)
      yield
    rescue RestClient::InternalServerError => error
      logger.send(
        @error_log_level,
        "Internal server error in elasticsearch. " +
        "Response: #{error.http_body}"
      )
      raise
    end

    def request(method, sub_path, payload)
      recording_elastic_error do
        logging_exception_body do
          RestClient::Request.execute(
            method: method,
            url:  url_for(sub_path),
            payload: payload,
            headers: {content_type: "application/json"}
          )
        end
      end
    end
  end
end
