require "document"
require "section"
require "logger"
require "rest-client"

class ElasticsearchWrapper

  class Client
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
      if sub_path.start_with? "/"
        # Sub-paths almost certainly shouldn't start with leading slashes,
        # since this will make the request relative to the server root
        @logger.warn 'Request sub-path "#{sub_path}" has a leading slash'
      end

      RestClient::Request.execute(
        method: method,
        url:  url_for(sub_path),
        payload: payload,
        headers: {content_type: "application/json"}
      )
    end

    # Forward on HTTP request methods, intercepting and resolving URLs
    [:get, :post, :put, :head, :delete].each do |method_name|
      define_method method_name do |sub_path, *args|
        RestClient.send(method_name, url_for(sub_path), *args)
      end
    end

  private
    def url_for(sub_path)
      if sub_path.start_with? "/"
        # Sub-paths almost certainly shouldn't start with leading slashes,
        # since this will make the request relative to the server root
        @logger.warn 'Request sub-path "#{sub_path}" has a leading slash'
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
    documents = documents.map(&:elasticsearch_export).map do |doc|
      index_action(doc).to_json + "\n" + doc.to_json
    end
    @client.request(:post, "_bulk", documents.join("\n"))
  end

  def search(query)
    # RestClient does not allow a payload with a GET request
    # so we have to call directly.u
    payload = {
        from: 0, size: 50,
        query: {
          bool: {
            must: {
              query_string: {
                fields: %w(title description indexable_content),
                query: query
              }
            },
            should: {
              query_string: {
                default_field: "format",
                query: "transaction OR #@recommended_format",
                boost: 3.0
              }
            }
          }
        },
        highlight: {
            pre_tags: %w(HIGHLIGHT_START),
            post_tags: %w(HIGHLIGHT_END),
            fields: {
                description: {},
                indexable_content: {}
            }
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
    {index: {_index: @index_name, _type: doc[:_type], _id: doc[:link]}}
  end
end
