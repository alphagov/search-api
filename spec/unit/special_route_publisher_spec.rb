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

  it "takes ownership of search routes" do
    stub_any_publishing_api_path_reservation
    @publisher.take_ownership_of_search_routes
    ["/search", "/search.json", "/search/opensearch.xml"].each do |path|
      assert_publishing_api(:put,
                            "#{Plek.find('publishing-api')}/paths#{path}",
                            {
                              "publishing_app": "search-api",
                              "override_existing": true,
                            })
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
