class SitemapPresenter
  def initialize(document)
    @document = document
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
    document.is_withdrawn ? 0.25 : 1
  end

private

  attr_reader :document

  def base_url
    Plek.current.website_root
  end
end
