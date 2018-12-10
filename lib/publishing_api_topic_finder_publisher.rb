require 'publishing_api_finder_publisher'

class PublishingApiTopicFinderPublisher
  TEMPLATE_CONTENT_ITEM_PATH = "config/topic_finders/prepare-individual-uk-leaving-eu.yml.erb".freeze

  def initialize(finder_config, timestamp = Time.now.iso8601)
    @finder_config = validate(finder_config)
    @timestamp = timestamp
  end

  def call
    template_content_item = File.read(TEMPLATE_CONTENT_ITEM_PATH)

    @finder_config.each do |item|
      config = {
        finder_content_id: item["finder_content_id"],
        timestamp: @timestamp,
        topic_content_id: item["topic_content_id"],
        topic_name: item["title"],
        topic_slug: item["slug"],
      }

      finder = YAML.safe_load(ERB.new(template_content_item).result(binding))

      PublishingApiFinderPublisher.new(finder, @timestamp).call
    end
  end

private

  # Ensure that the config is an array of the right sort of hashes
  def validate(finder_config)
    raise TopicFinderValidationError unless finder_config.all? do |item|
      %w(finder_content_id topic_content_id title slug).all? { |key| item.has_key? key }
    end
    finder_config
  end
end

class TopicFinderValidationError < StandardError; end
