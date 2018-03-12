require "gds_api/publishing_api_v2"

class PublishingApiFinderPublisher
  def initialize(finder, timestamp = Time.now.iso8601, logger = Logger.new(STDOUT))
    @finder = finder
    @logger = logger
    @timestamp = timestamp
  end

  def call
    if pre_production?(finder)
      publish(finder)
    else
      logger.info("Not publishing #{finder['name']} because it's not pre_production")
    end
  end

private

  attr_reader :finder, :logger, :timestamp

  def publishing_api
    @publishing_api ||= GdsApi::PublishingApiV2.new(
      Plek.new.find('publishing-api'),
      bearer_token: ENV['PUBLISHING_API_BEARER_TOKEN'] || 'example',
      timeout: 10,
    )
  end

  def publish(finder)
    export_finder(finder)
  end

  def pre_production?(finder)
    finder["pre_production"] == true
  end

  def export_finder(finder)
    presenter = FinderContentItemPresenter.new(finder, timestamp)

    logger.info("Publishing '#{presenter.name}' finder")

    publishing_api.put_content(presenter.content_id, presenter.present)
    publishing_api.patch_links(presenter.content_id, presenter.present_links)
    publishing_api.publish(presenter.content_id)
  end
end

class FinderContentItemPresenter
  attr_reader :content_id, :finder, :name, :timestamp

  def initialize(finder, timestamp)
    @finder = finder
    @content_id = finder["content_id"]
    @name = finder["name"]
    @timestamp = timestamp
  end

  def present
    {
      base_path: finder["base_path"],
      description: finder["description"],
      details: finder["details"].except("reject"),
      document_type: finder["document_type"],
      locale: "en",
      phase: "live",
      public_updated_at: timestamp,
      publishing_app: finder["publishing_app"],
      rendering_app: finder["rendering_app"],
      routes: finder["routes"],
      schema_name: finder["schema_name"],
      title: finder["title"],
      update_type: "minor",
    }
  end

  def present_links
    { content_id: content_id, links: {} }
  end
end
