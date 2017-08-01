class SitemapPresenter
  def initialize(document, format_boost_calculator)
    @document = document
    @format_boost_calculator = format_boost_calculator
    @logger = Logging.logger[self]
  end

  def url
    if document.link.start_with?("http")
      document.link
    else
      URI.join(base_url, document.link).to_s
    end
  end

  def last_updated
    return nil unless document.public_timestamp

    # Attempt to parse timestamp to validate it
    DateTime.iso8601(document.public_timestamp)
    document.public_timestamp
  rescue ArgumentError
    @logger.warn("Invalid timestamp '#{document.public_timestamp}' for page '#{document.link}'")
    # Ignore invalid or missing timestamps
    nil
  end

  def priority
    withdrawn_status_boost * format_boost_calculator.boost(document.format)
  end

private

  attr_reader :document, :format_boost_calculator

  def base_url
    Plek.current.website_root
  end

  def withdrawn_status_boost
    document.is_withdrawn ? 0.25 : 1
  end
end
