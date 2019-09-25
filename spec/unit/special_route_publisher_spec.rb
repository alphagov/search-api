require "spec_helper"

RSpec.describe SpecialRoutePublisher do
  before do
    GovukContentSchemaTestHelpers.configure do |config|
      config.schema_type = "publisher_v2"
      config.project_root = File.expand_path("../../../", __FILE__)
    end

    @publishing_api = double

    logger = Logger.new(STDOUT)
    logger.level = Logger::WARN

    @publisher = described_class.new(
      publishing_api: @publishing_api,
      logger: logger,
    )
  end

  it "should publish a valid content item for special routes" do
    @publisher.routes.each do |route|
      expect(@publishing_api).to receive(:put_content) do |_, payload|
        assert_valid_content_item(payload)
      end
      expect(@publishing_api).to receive(:publish)

      @publisher.publish(route)
    end
  end

  def assert_valid_content_item(payload)
    validator = GovukContentSchemaTestHelpers::Validator.new(
      "special_route",
      "schema",
      payload,
    )

    expect(validator.valid?).to be true
  end
end
