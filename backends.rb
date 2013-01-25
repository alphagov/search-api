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
    @backends ||= Hash.new do |hash, key|
      @logger.debug "Instantiating #{key} search backend"
      backend_settings = @settings.backends[key] && @settings.backends[key].symbolize_keys
      hash[key] = backend_settings && build_backend(backend_settings)
    end
  end

private

  def build_backend(backend_settings)
    case backend_settings[:type]
    when "none"
      @logger.debug "Using null backend"
      NullBackend.new(@logger)
    when "elasticsearch"
      @logger.debug "Using elasticsearch backend"
      ElasticsearchWrapper.new(
        backend_settings,
        @logger,
        backend_settings[:format_filter]
      )
    else
      raise RuntimeError, "Unknown backend '#{backend_settings[:type].inspect}'"
    end
  end
end
