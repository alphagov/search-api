class SitemapPresenter
  GOVUK_LAUNCH_DATE = Time.new(2012, 10, 17).freeze

  def initialize(document, property_boost_calculator)
    @document = document
    @property_boost_calculator = property_boost_calculator
    @logger = Logging.logger[self]
  end

  def to_h
    {
      url: url,
      last_updated: last_updated,
      priority: priority,
    }
  end

private

  attr_reader :document, :property_boost_calculator

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
    parsed_date = Time.parse(timestamp)

    # Limit timestamps for old documents to GOV.UK was launch date
    return GOVUK_LAUNCH_DATE.iso8601 if parsed_date < GOVUK_LAUNCH_DATE

    parsed_date.iso8601
  rescue ArgumentError
    @logger.warn("Invalid timestamp '#{timestamp}' for page '#{document['link']}'")
    # Ignore invalid or missing timestamps
    nil
  end

  def priority
    property_boost_calculator.boost(document)
  end

  def base_url
    Plek.new.website_root
  end
end
