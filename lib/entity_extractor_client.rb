require 'rest-client'
require 'json'

class EntityExtractorClient
  attr_reader :service_base_url
  def initialize(service_base_url)
    @service_base_url = URI.parse(service_base_url)
  end

  def call(document)
    response = RestClient.post(extract_url, document)
    JSON.parse(response)
  end

private
  def extract_url
    service_base_url.clone.tap do |url|
      url.path = '/extract'
    end.to_s
  end
end
