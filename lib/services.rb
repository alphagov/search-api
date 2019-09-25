require "active_support/cache"

module Services
  def self.publishing_api
    GdsApi::PublishingApiV2.new(
      Plek.find("publishing-api"),
      bearer_token: ENV["PUBLISHING_API_BEARER_TOKEN"] || "example",

      # The cache is not threadsafe so using it can cause bulk imports to break
      disable_cache: true,

      # Currently, expanded-links consistently takes a long time for some
      # content. This is required for indexing, so it's better to wait for this
      # to complete than abort the request.
      timeout: 20,
    )
  end

  # Build a client to connect to one or more elasticsearch nodes.
  # hosts should be a comma separated string. Valid formats
  # are documented at http://www.rubydoc.info/gems/elasticsearch-transport#Setting_Hosts
  #
  # Be careful when setting a short timeout value. You may see confusing HTTP
  # 4XX responses rather than timeout errors because the Elasticsearch client
  # uses Faraday which uses Net::HTTP, and Net::HTTP retries idempotent requests
  # which time out (including PUT and DELETE requests). So the first, slow,
  # request succeeds (but times out) and the second retry request returns an
  # error because the operation has already been run.
  def self.elasticsearch(cluster: nil, hosts: ENV["ELASTICSEARCH_HOSTS"] || "http://localhost:9200", timeout: 5, retry_on_failure: false)
    Elasticsearch::Client.new(
      hosts: cluster ? cluster.uri : hosts,
      request_timeout: timeout,
      logger: Logging.logger[self],
      retry_on_failure: retry_on_failure,
      transport_options: { headers: { "Content-Type" => "application/json" } },
    )
  end

  def self.statsd_client
    Cache.get(Cache::STATSD_CLIENT) do
      Statsd.new.tap { |sd| sd.namespace = "govuk.app.search-api" }
    end
  end

  def self.cache
    @cache ||= ActiveSupport::Cache.lookup_store(:memory_store)
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
