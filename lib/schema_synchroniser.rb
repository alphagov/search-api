class SchemaSynchroniser
  def initialize(index_name, client = Services.elasticsearch)
    @index_name = index_name
    @client = client
  end

  def sync_mappings(mapping, logger = Logger.new($stdout))
    ElasticsearchClient.put_mapping(index_name: @index_name, mapping:, client: @client)
    logger.info "Updated mappings for index: #{@index_name}"
  rescue OpenSearch::Transport::Transport::Errors::BadRequest => e
    logger.warn "Unable to update mappings for index: #{@index_name}; #{e.message}"
    raise
  end
end
