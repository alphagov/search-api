module ContentItemPublisher
  def self.publish(config:, timestamp: Time.now.iso8601, logger: Logger.new($stdout))
    config_file = YAML.load_file(config)

    if config_file["document_type"] == "finder_email_signup"
      ContentItemPublisher::FinderEmailSignupPublisher.new(config_file, timestamp).call
    elsif config_file["document_type"] == "finder"
      ContentItemPublisher::FinderPublisher.new(config_file, timestamp).call
    else
      raise "Invalid document type"
    end
    logger.info "Published #{config}..."
  end
end
