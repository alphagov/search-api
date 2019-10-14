class SitemapPresenter
  GOVUK_LAUNCH_DATE = DateTime.new(2012, 10, 17).freeze

  def initialize(document, property_boost_calculator)
    @document = document
    @property_boost_calculator = property_boost_calculator
    @logger = Logging.logger[self]
  end

  def url
    if document["link"].start_with?("http")
      document["link"]
    else
      URI.join(base_url, document["link"]).to_s
    end
  end

  def last_updated
    timestamp = document.fetch("updated_at", document.fetch("public_timestamp", nil))
    return nil unless timestamp

    # Attempt to parse timestamp to validate it
    parsed_date = DateTime.iso8601(timestamp)

    # Limit timestamps for old documents to GOV.UK was launch date
    return GOVUK_LAUNCH_DATE.iso8601 if parsed_date < GOVUK_LAUNCH_DATE

    timestamp
  rescue ArgumentError
    @logger.warn("Invalid timestamp '#{timestamp}' for page '#{document['link']}'")
    # Ignore invalid or missing timestamps
    nil
  end

  def priority
    withdrawn_status_boost * property_boost_calculator.boost(document)
  end

private

  attr_reader :document, :property_boost_calculator

  def base_url
    Plek.current.website_root
  end

  def withdrawn_status_boost
    document["is_withdrawn"] ? 0.25 : 1
  end
end
