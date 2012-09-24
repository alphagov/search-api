require "solr_wrapper"
require "elasticsearch_wrapper"
require "null_backend"

class Backends
  def initialize(settings, logger = nil)
    @settings = settings
    @logger = logger || Logger.new("/dev/null")
  end

  def backends
    @backends ||= Hash.new do |hash, key|
      @logger.info "Instantiating #{key} search backend"
      backend_settings = @settings.backends[key] && @settings.backends[key].symbolize_keys
      hash[key] = backend_settings && build_backend(backend_settings)
    end
  end

  def primary_search
    backends[:primary]
  end

  def secondary_search
    backends[:secondary]
  end

private

  def build_backend(backend_settings)
    case backend_settings[:type]
    when "none"
      @logger.info "Using null backend"
      NullBackend.new(@logger)
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
      raise RuntimeError, "Unknown backend '#{backend_settings[:type].inspect}'"
    end
  end
end
