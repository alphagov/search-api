require 'gds_api/content_api'
require 'gds_api/publishing_api_v2'

module Services
  def self.content_api
    @content_api ||= GdsApi::ContentApi.new(
      Plek.find('contentapi'),

      # We'll rarely look up the same content item twice in quick succession,
      # so the cache isn't much use. Additionally, it's not threadsafe, so
      # using it can cause bulk imports to break.
      disable_cache: true
    )
  end

  def self.publishing_api
    @publishing_api ||= GdsApi::PublishingApiV2.new(
      Plek.find('publishing-api'),
      bearer_token: ENV['PUBLISHING_API_BEARER_TOKEN'] || 'example',

      # The cache is not threadsafe so using it can cause bulk imports to break
      disable_cache: true
    )
  end
end
