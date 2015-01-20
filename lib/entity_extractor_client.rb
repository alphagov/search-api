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
  end

  def call(document)
    response = RestClient.post(extract_url, document, @options)
    JSON.parse(response)
  end

private
  attr_reader :logger

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
