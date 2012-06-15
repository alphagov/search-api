require "document"
require "section"
require "logger"
require "rest-client"

class ElasticsearchWrapper
  def initialize(settings, recommended_format, logger=Logger.new("/dev/null"))
    @settings, @recommended_format, @logger = settings, recommended_format, logger
  end

  def add(documents)
    documents = documents.map(&:elasticsearch_export).map do |doc|
      index_action(doc).to_json + "\n" + doc.to_json
    end
    request(:post, "/_bulk", documents.join("\n"))
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
    result = request(:get, "/_search", payload)
    result = JSON.parse(result)
    result['hits']['hits'].map { |hit|
      Document.from_hash(hit['_source'])
    }
  end

  private
  def request(method, sub_path, payload)
    RestClient::Request.execute(
        method: method,
        url: url_for(sub_path),
        payload: payload,
        headers: {content_type: "application/json"}
    )
  end
  def url_for(sub_path)
    "#{@settings['baseurl']}#{@settings['indexname']}#{sub_path}"
  end
  def index_action(doc)
    {index: {_index: @settings['indexname'], _type: doc[:_type], _id: doc[:link]}}
  end
end