require "logging"
require "rest-client"
require "uri"
require "gds_api/govuk_headers"
require "elasticsearch/transport"
require "pry-byebug"

module Transport
  class Client
    # Sub-paths almost certainly shouldn't start with leading slashes,
    # since this will make the request relative to the server root
    SAFE_ABSOLUTE_PATHS = ["/_bulk", "/_status", "/_aliases", "/_search/scroll"].freeze

    def initialize(base_uri, args = {})
      # TODO: initialise client with multiple hosts instead
      base_uri = URI(base_uri).dup

      # TODO: scoping to a path can go away when we use elasticsearch-api
      @base_path = base_uri.path
      @base_path = @base_path.gsub(/^\//, "").gsub(/\/$/, "")

      base_uri.path = ''
      @client = Elasticsearch::Client.new(hosts: base_uri.to_s, transport_options: { headers: { "Content-Type" => "application/json" } })

      # TODO: pass to client
      @error_log_level = :error
      @timeout = args[:timeout]
      @open_timeout = args[:open_timeout]
    end

    def get(path, _headers = {})
      # TODO: remove headers
      request(:get, path, nil)
    end

    def post(path, payload, _headers = {})
      # TODO: remove headers
      request(:post, path, payload)
    end

    def patch(path, payload, _headers = {})
      # TODO: remove headers
      request(:patch, path, payload)
    end

    def put(path, payload, _headers = {})
      # TODO: remove headers
      request(:put, path, payload)
    end

    def delete(path, _headers = {})
      # TODO: remove headers
      request(:delete, path, nil)
    end

    def head(path, _headers = {})
      # TODO: remove headers
      request(:head, path, nil)
    end

    def options(path, _headers = {})
      # TODO: remove headers
      request(:options, path, nil)
    end

    # RestClient doesn't natively support sending payloads with these request
    # methods, but elasticsearch requires them for certain operations
    def get_with_payload(path, payload, _headers = {})
      # TODO: remove headers
      # TODO: expects hash instead of string for payload
      request(:get, path, payload)
    end

    def delete_with_payload(path, payload, _headers = {})
      # TODO: remove headers
      request(:delete, path, payload)
    end

  private

    def logger
      Logging.logger[self]
    end

    def url_for(sub_path)
      # FIXME: make this less awful
      return nil if sub_path.nil?

      if sub_path.is_a? URI
        sub_path = sub_path.to_s
      end

      if sub_path.start_with? "/"
        path_without_query = sub_path.split("?")[0]
        unless SAFE_ABSOLUTE_PATHS.include? path_without_query
          logger.error "Request sub-path '#{sub_path}' has a leading slash"
          raise ArgumentError, "Only whitelisted absolute paths are allowed"
        end

        # Leading slash indicates absolute URL...
        sub_path[1..-1]
      elsif @base_path == ""
        # Relative to root
        sub_path
      else
        # Relative to our existing base path
        @base_path + "/" + sub_path
      end
    end

    def logging_exception_body(&_block)
      yield
    rescue RestClient::BadRequest => error
      logger.send(
        @error_log_level,
        "BadRequest error from elasticsearch. " +
        "Response: #{error.http_body}"
      )
      raise
    rescue RestClient::InternalServerError => error
      logger.send(
        @error_log_level,
        "Internal server error in elasticsearch. " +
        "Response: #{error.http_body}"
      )
      raise
    end

    def request(method, path, payload = nil)
      # TODO: removed headers param from the interface because the client doesn't support it
      # TODO: ensure client logging works as well as old logging
      #       i.e. logger.debug(args.reject { |k| k == :payload })
      # TODO: new response type Elasticsearch::Transport::Transport::Response containing :status, :body, :headers
      # TODO: new exception hierarchy Elasticsearch::Transport::Transport::Error
      @client.perform_request(method.to_s.upcase, url_for(path), {}, payload).body
    end
  end
end
