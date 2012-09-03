require "document"
require "section"
require "logger"
require "rest-client"

class ElasticsearchWrapper
  def initialize(settings, logger=Logger.new("/dev/null"))
    @settings, @logger = settings, logger
  end

  def add(documents)
    documents = documents.map(&:elasticsearch_export).map do |doc|
      index_action(doc).to_json + "\n" + doc.to_json
    end
    url = "#{@settings['baseurl']}#{@settings['indexname']}/_bulk"

    RestClient.post(url,
      documents.join("\n"),
      content_type: "application/json"
    )
  end

  private
  def index_action(doc)
    {index: {_index: @settings['indexname'], _type: doc[:_type], _id: doc[:link]}}
  end
end