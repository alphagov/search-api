class SchemaSynchroniser
  attr_reader :errors

  def initialize(index_name, client = Services.elasticsearch)
    @index_name = index_name
    @client = client
  end

  def sync_mappings(mapping, logger = Logger.new($stdout))
    @errors = begin
      @client.indices.put_mapping(index: @index_name, type: "generic-document", body: mapping)
      logger.info "Updated mappings for index: #{@index_name}"
      {}
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
      logger.warn "Unable to update mappings for index: #{@index_name}; #{e.message}"
      { "generic-document" => e }
    end
  end

  def synchronised_types
    %w[generic-document].difference(@errors.keys)
  end
end
