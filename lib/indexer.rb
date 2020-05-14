module Indexer
  class PublishingApiError < StandardError; end

  # Some applications send the `content_id` for their items. This means we can
  # skip the lookup from the publishing-api.
  def self.find_content_id(base_path, logger)
    GdsApi.with_retries(maximum_number_of_attempts: 5) do
      Services.publishing_api.lookup_content_id(base_path: base_path)
    end
  rescue GdsApi::TimedOutException => e
    logger.error("Timeout looking up content ID for #{base_path}")
    GovukError.notify(
      e,
      extra: {
        error_message: "Timeout looking up content ID",
        base_path: base_path,
      },
    )
    raise Indexer::PublishingApiError
  rescue GdsApi::HTTPErrorResponse => e
    logger.error("HTTP error looking up content ID for #{base_path}: #{e.message}")
    # We capture all GdsApi HTTP exceptions here so that we can send them
    # manually to Sentry. This allows us to control the message and parameters
    # such that errors are grouped in a sane manner.
    GovukError.notify(
      e,
      extra: {
        message: "HTTP error looking up content ID",
        base_path: base_path,
        error_code: e.code,
        error_message: e.message,
        error_details: e.error_details,
      },
    )
    raise Indexer::PublishingApiError
  end
end
