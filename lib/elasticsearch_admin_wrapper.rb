require "elasticsearch_wrapper"
require "logger"

class ElasticsearchAdminWrapper

  def initialize(settings, schema, logger = nil)
    @client = ElasticsearchWrapper::Client.new(settings, logger)
    @schema = schema
    @logger = logger || Logger.new("/dev/null")
  end

  def index_exists?
    server_status = JSON.parse(@client.get("/_status"))
    server_status["indices"].keys.include? @client.index_name
  end

  def create_index
    # Create the elasticsearch index if it does not exist
    # If it does exist, close the index and apply the updated analysis settings

    index_payload = @schema["index"]

    if index_exists?
      @logger.info "Index already exists: updating settings"
      @client.post("_close", nil)
      @client.put("_settings", index_payload["settings"].to_json)
      @client.post("_open", nil)
      @logger.info "Settings updated"
      return :updated
    else
      @client.put("", index_payload.to_json)
      @logger.info "Index created"
      return :created
    end
  end

  def create_index!
    # Delete and recreate the elasticsearch index
    begin
      @client.delete ""
    rescue RestClient::ResourceNotFound
    end

    create_index
  end

  def put_mappings
    # Create or update the mappings in the current index
    @schema["mapping"].each do |mapping_type, mapping|
      @logger.info 'Setting mapping for the "#{mapping_type}" type'
      @logger.debug({mapping_type => mapping}.to_json)

      begin
        @client.put(
          "#{mapping_type}/_mapping",
          {mapping_type => mapping}.to_json
        )
      rescue RestClient::Exception => e
        @logger.info e.http_body
        raise
      end
    end
  end
end
