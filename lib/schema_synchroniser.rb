class SchemaSynchroniser
  def initialize(index_name, client = Services.opensearch)
    @index_name = index_name
    @client = client
  end

  def sync_mappings(mapping, logger = Logger.new($stdout))
    @client.indices.put_mapping(index: @index_name, body: mapping)
    logger.info "Updated mappings for index: #{@index_name}"
  rescue OpenSearch::Transport::Transport::Errors::BadRequest => e
    logger.warn "Unable to update mappings for index: #{@index_name}; #{e.message}"
    raise
  end
end
