require "logging"

module Elasticsearch
  class Client

    # Sub-paths almost certainly shouldn't start with leading slashes,
    # since this will make the request relative to the server root
    SAFE_ABSOLUTE_PATHS = ["/_bulk", "/_status", "/_aliases", "/_search/scroll"]

    def initialize(base_uri, args = {})
      @base_uri = base_uri
      @error_log_level = :error
      @timeout = args[:timeout]
      @open_timeout = args[:open_timeout]
    end

    def get(path, headers = {})
      request(:get, path, nil, headers)
    end

    def post(path, payload, headers = {})
      request(:post, path, payload, headers)
    end

    def patch(path, payload, headers = {})
      request(:patch, path, payload, headers)
    end

    def put(path, payload, headers = {})
      request(:put, path, payload, headers)
    end

    def delete(path, headers = {})
      request(:delete, path, nil, headers)
    end

    def head(path, headers = {})
      request(:head, path, nil, headers)
    end

    def options(path, headers = {})
      request(:options, path, nil, headers)
    end

    # RestClient doesn't natively support sending payloads with these request
    # methods, but elasticsearch requires them for certain operations
    def get_with_payload(path, payload, headers = {})
      request(:get, path, payload, headers)
    end

    def delete_with_payload(path, payload, headers={})
      request(:delete, path, payload, headers)
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

    def request(method, path, payload = nil, headers = {})
      if headers == {}
        headers[:content_type] = "application/json"
      end

      logging_exception_body do
        args = {
          method: method,
          url: url_for(path),
        }
        args[:payload] = payload if payload
        args[:headers] = headers if headers
        args[:timeout] = @timeout if @timeout
        args[:open_timeout] = @open_timeout if @open_timeout
        logger.debug(args.reject { |k| k == :payload })
        RestClient::Request.execute(args)
      end
    end
  end
end
