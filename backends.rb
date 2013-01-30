require "elasticsearch_wrapper"
require "null_backend"
require "active_support/core_ext/module/delegation"


class Backends
  delegate :[], to: :backends

  def initialize(settings, logger = nil)
    @settings = settings
    @logger = logger || Logger.new("/dev/null")
  end

  def backends
    @backends ||= Hash.new do |hash, backend_name|
      @logger.debug "Instantiating #{backend_name} search backend"
      backend_settings = @settings.backends[backend_name] && @settings.backends[backend_name].symbolize_keys
      hash[backend_name] = backend_settings && build_backend(backend_settings, mappings_for(backend_name))
    end
  end

private

  def build_backend(backend_settings, mappings)
    case backend_settings[:type]
    when "none"
      @logger.debug "Using null backend"
      NullBackend.new(@logger)
    when "elasticsearch"
      @logger.debug "Using elasticsearch backend"
      ElasticsearchWrapper.new(
        backend_settings,
        mappings,
        @logger,
        backend_settings[:format_filter]
      )
    else
      raise RuntimeError, "Unknown backend '#{backend_settings[:type].inspect}'"
    end
  end

  def mappings_for(backend_name)
    all_mappings = @settings.elasticsearch_schema["mappings"]
    all_mappings[backend_name.to_s] || all_mappings["default"]
  end
end
