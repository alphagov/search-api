require 'publishing_api_finder_publisher'

class PrepareEuExitFinderPublisher
  TEMPLATE_PATH = "config/prepare-eu-exit.yml.erb".freeze

  PrepareEuExitFinderValidationError = Class.new(StandardError)

  def initialize(topics, timestamp = Time.now.iso8601)
    @topics = validate(topics)
    @timestamp = timestamp
  end

  def call
    template = ERB.new(File.read(TEMPLATE_PATH))

    @topics.each do |topic|
      schema_config = {
        finder_content_id: topic["finder_content_id"],
        timestamp: @timestamp,
        topic_content_id: topic["topic_content_id"],
        topic_name: topic["title"],
        topic_slug: topic["slug"],
      }

      schema = YAML.safe_load(template.result_with_hash(config: schema_config))

      PublishingApiFinderPublisher.new(schema, @timestamp).call
    end
  end

private

  # Ensure that the config is an array of the right sort of hashes
  def validate(finder_config)
    raise PrepareEuExitFinderValidationError unless finder_config.all? do |item|
      %w(finder_content_id topic_content_id title slug).all? { |key| item.has_key? key }
    end
    finder_config
  end
end
