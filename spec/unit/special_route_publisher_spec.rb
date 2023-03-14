require "spec_helper"
require "govuk_schemas/validator"

RSpec.describe SpecialRoutePublisher do
  before do
    @publishing_api = double

    logger = Logger.new($stdout)
    logger.level = Logger::WARN

    @publisher = described_class.new(
      publishing_api: @publishing_api,
      logger:,
    )
  end

  it "publishes a valid content item for special routes" do
    @publisher.routes.each do |route|
      expect(@publishing_api).to receive(:put_content) do |_, payload|
        assert_valid_content_item(payload)
      end
      expect(@publishing_api).to receive(:publish)

      @publisher.publish(route)
    end
  end

  def assert_valid_content_item(payload)
    validator = GovukSchemas::Validator.new(
      "special_route",
      "publisher",
      payload,
    )

    expect(validator.valid?).to be true
  end
end
