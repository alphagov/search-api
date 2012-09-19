require "document"
require "section"
require "logger"
require "cgi"
require "rest-client"

class ElasticsearchWrapper

  class Client

    # Sub-paths almost certainly shouldn't start with leading slashes,
    # since this will make the request relative to the server root
    SAFE_ABSOLUTE_PATHS = ["/_bulk"]

    def initialize(settings, logger = nil)
      missing_keys = [:server, :port, :index_name].reject { |k| settings[k] }
      if missing_keys.any?
        raise RuntimeError, "Missing keys: #{missing_keys.join(", ")}"
      end
      @base_url = URI::HTTP.build(
        host: settings[:server],
        port: settings[:port],
        path: "/#{settings[:index_name]}/"
      )

      @logger = logger || Logger.new("/dev/null")
    end

    def request(method, sub_path, payload)
      begin
        RestClient::Request.execute(
          method: method,
          url:  url_for(sub_path),
          payload: payload,
          headers: {content_type: "application/json"}
        )
      rescue RestClient::InternalServerError => error
        @logger.error(
          "Internal server error in elasticsearch. " +
          "Response: #{error.http_body}"
        )
        raise
      end
    end

    # Forward on HTTP request methods, intercepting and resolving URLs
    [:get, :post, :put, :head, :delete].each do |method_name|
      define_method method_name do |sub_path, *args|
        full_url = url_for(sub_path)
        @logger.debug "Sending #{method_name.upcase} request to #{full_url}"
        args.each_with_index do |argument, index|
          @logger.debug "Argument #{index + 1}: #{argument.inspect}"
        end
        RestClient.send(method_name, url_for(sub_path), *args)
      end
    end

  private
    def url_for(sub_path)
      if sub_path.start_with? "/" and ! SAFE_ABSOLUTE_PATHS.include? sub_path
        @logger.error "Request sub-path '#{sub_path}' has a leading slash"
        raise ArgumentError, "Only whitelisted absolute paths are allowed"
      end

      # Addition on URLs does relative resolution
      (@base_url + sub_path).to_s
    end
  end

  # TODO: support the format_filter option here
  def initialize(settings, recommended_format, logger = nil, format_filter = nil)
    @client = Client.new(settings, logger)
    @index_name = settings[:index_name]
    raise ArgumentError, "Missing index_name parameter" unless @index_name
    @recommended_format = recommended_format
    @logger = logger || Logger.new("/dev/null")

    raise RuntimeError, "Format filters not yet supported" if format_filter
  end

  def add(documents)
    @logger.info "Adding #{documents.size} document(s) to elasticsearch"
    documents = documents.map(&:elasticsearch_export).map do |doc|
      index_action(doc).to_json + "\n" + doc.to_json
    end
    # Ensure the request payload ends with a newline
    @client.post("_bulk", documents.join("\n") + "\n", content_type: :json)
  end

  def get(link)
    @logger.info "Retrieving document with link '#{link}'"
    begin
      response = @client.get("_all/#{CGI.escape(link)}")
    rescue RestClient::ResourceNotFound
      return nil
    end

    Document.from_hash(JSON.parse(response.body)["_source"])
  end

  def search(query, format_filter = nil)

    raise "Format filter not yet supported" if format_filter

    # RestClient does not allow a payload with a GET request
    # so we have to call @client.request directly.
    payload = {
        from: 0, size: 50,
        query: {
          query_string: { query: query }
        }
    }.to_json
    result = @client.request(:get, "_search", payload)
    result = JSON.parse(result)
    result['hits']['hits'].map { |hit|
      Document.from_hash(hit['_source'])
    }
  end

  private
  def index_action(doc)
    {index: {_type: doc[:_type], _id: doc[:link]}}
  end
end
