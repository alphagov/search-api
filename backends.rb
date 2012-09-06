class Backends

  def initialize(settings, logger = nil)
    @settings, @logger = settings, logger
  end

  def primary_search
    @logger.info "Instantiating primary search backend" unless @primary_search
    @primary_search ||= build_backend(@settings.primary_search)
  end

  def secondary_search
    @logger.info "Instantiating secondary search backend" unless @secondary_search
    @secondary_search ||= build_backend(@settings.secondary_search)
  end

private

  def build_backend(backend_settings)
    case backend_settings[:type]
    when "none"
      @logger.info "Using null backend"
      NullBackend.new(logger)
    when "solr"
      @logger.info "Using Solr backend"
      SolrWrapper.new(
        DelSolr::Client.new(backend_settings),
        @settings.recommended_format,
        @logger,
        backend_settings[:format_filter]
      )
    when "elasticsearch"
      @logger.info "Using elasticsearch backend"
      ElasticsearchWrapper.new(
        backend_settings,
        @settings.recommended_format,
        @logger,
        backend_settings[:format_filter]
      )
    else
      raise RuntimeError, "Unknown backend '#{backend_settings[:type]}'"
    end
  end
end