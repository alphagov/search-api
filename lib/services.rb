require "elasticsearch"
require 'statsd'
require 'gds_api/publishing_api_v2'

module Services
  def self.publishing_api
    @publishing_api ||= GdsApi::PublishingApiV2.new(
      Plek.find('publishing-api'),
      bearer_token: ENV['PUBLISHING_API_BEARER_TOKEN'] || 'example',

      # The cache is not threadsafe so using it can cause bulk imports to break
      disable_cache: true,

      # Currently, expanded-links consistently takes a long time for some
      # content. This is required for indexing, so it's better to wait for this
      # to complete than abort the request.
      timeout: 20
    )
  end

  # Build a client to connect to one or more elasticsearch nodes.
  # hosts should be a comma separated string. Valid formats
  # are documented at http://www.rubydoc.info/gems/elasticsearch-transport#Setting_Hosts
  def self.elasticsearch(hosts: ENV['ELASTICSEARCH_HOSTS'] || 'http://localhost:9200', timeout: 5)
    Elasticsearch::Client.new(
      hosts: hosts,
      request_timeout: timeout,
      logger: Logging.logger[self],
      transport_options: { headers: { "Content-Type" => "application/json" } }
    )
  end

  def self.statsd_client
    @statsd_client ||= Statsd.new.tap { |sd| sd.namespace = "govuk.app.rummager" }
  end
end

# First attempt at a retry-thing. Keeping it inside this repo for ease of
# testing. Once it's good we'll move this up to GdsApi adapters.
module GdsApi
  def self.with_retries(maximum_number_of_attempts:)
    attempts = 0
    begin
      attempts += 1
      yield
    rescue Timeout::Error, GdsApi::TimedOutException => e
      raise e if attempts >= maximum_number_of_attempts
      sleep sleep_time_after_attempt(attempts)
      retry
    end
  end

  # If attempt 1 fails, it will wait 0.03 seconds before trying again
  # If attempt 2 fails, it will wait 0.09 seconds before trying again
  # If attempt 3 fails, it will wait 0.27 seconds before trying again
  # If attempt 4 fails, it will wait 0.81 seconds before trying again
  # If attempt 5 fails, it will wait 2.43 seconds before trying again
  # If attempt 6 fails, it will wait 7.29 seconds before trying again
  def self.sleep_time_after_attempt(current_attempt)
    (3.0**current_attempt) / 100
  end
end
