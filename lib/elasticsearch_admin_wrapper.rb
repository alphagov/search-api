require "elasticsearch_wrapper"
require "logger"

class ElasticsearchAdminWrapper

  def initialize(settings, schema, logger = nil)
    @client = ElasticsearchWrapper::Client.new(settings, logger)
    @schema = schema
    @logger = logger || Logger.new("/dev/null")
  end

  def create_index
    # Create the elasticsearch index if it does not exist
    # If the index was created, return true; if it existed, return false

    index_payload = @schema["index"]

    @logger.info "Trying to create elasticsearch index"
    begin
      @client.put("", index_payload.to_json)
      @logger.info "Index created"
      return true
    rescue RestClient::BadRequest => error
      # Have to rescue and inspect the BadRequest here, because elasticsearch
      # doesn't do idempotent PUT requests for index creation
      error_message = JSON.parse(error.http_body)["error"]
      if error_message.start_with? "IndexAlreadyExistsException"
        @logger.info "Index already exists"
        return false
      else
        raise
      end
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
      @logger.info "Setting mapping for the '#{mapping_type}' type"
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
