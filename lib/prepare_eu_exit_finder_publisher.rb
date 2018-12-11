require 'publishing_api_finder_publisher'

class PrepareEuExitFinderPublisher
  TEMPLATE_CONTENT_ITEM_PATH = "config/prepare-eu-exit.yml.erb".freeze

  def initialize(topics, timestamp = Time.now.iso8601)
    @topics = validate(topics)
    @timestamp = timestamp
  end

  def call
    template_content_item = File.read(TEMPLATE_CONTENT_ITEM_PATH)

    @topics.each do |topic|
      config = {
        finder_content_id: topic["finder_content_id"],
        timestamp: @timestamp,
        topic_content_id: topic["topic_content_id"],
        topic_name: topic["title"],
        topic_slug: topic["slug"],
      }

      finder = YAML.safe_load(ERB.new(template_content_item).result(binding))

      PublishingApiFinderPublisher.new(finder, @timestamp).call
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

class PrepareEuExitFinderValidationError < StandardError; end
