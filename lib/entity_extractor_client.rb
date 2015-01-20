require 'rest-client'
require 'json'

class EntityExtractorClient
  attr_reader :service_base_url

  DEFAULT_OPEN_TIMEOUT_IN_SECONDS = 1
  DEFAULT_READ_TIMEOUT_IN_SECONDS = 1

  def initialize(service_base_url, options = {})
    @service_base_url = URI.parse(service_base_url)
    @options = default_options.merge(options)
    @logger = options[:logger] || Logging.logger[self]
    @swallow_connection_errors = options[:swallow_connection_errors] || false
    @had_connection_error = false
  end

  def call(document)
    if swallow_connection_errors? && had_connection_error?
      nil
    else
      response = RestClient.post(extract_url, document, @options)
      JSON.parse(response)
    end
  rescue Errno::ECONNREFUSED => e
    if swallow_connection_errors?
      logger.error(e)
      @had_connection_error = true
      nil
    else
      raise
    end
  end

private
  attr_reader :logger

  def swallow_connection_errors?
    @swallow_connection_errors
  end

  def had_connection_error?
    @had_connection_error
  end

  def extract_url
    service_base_url.clone.tap do |url|
      url.path = '/extract'
    end.to_s
  end

  def default_options
    {
      timeout: DEFAULT_READ_TIMEOUT_IN_SECONDS,
      open_timeout: DEFAULT_OPEN_TIMEOUT_IN_SECONDS
    }
  end
end
