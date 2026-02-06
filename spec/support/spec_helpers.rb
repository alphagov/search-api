require "gds_api/test_helpers/publishing_api"

module SpecHelpers
  include GdsApi::TestHelpers::PublishingApi
  EXAMPLE_GENERATOR_RETRIES = 5

  def self.included(base)
    base.after do
      Timecop.return
    end
  end

  def search_query_params(options = {})
    Search::QueryParameters.new({
      start: 0,
      count: 20,
      query: "cheese",
      order: nil,
      filters: {},
      return_fields: nil,
      aggregates: nil,
      debug: {},
      ab_tests: {},
    }.merge(options))
  end

  # This works because we first try to look up the content id for the base path.
  def stub_tagging_lookup
    stub_publishing_api_has_lookups({})
  end

  # need to add additional page_traffic data in order to set maximum allowed ranking value
  def setup_page_traffic_data(document_count:)
    document_count.times.each do |i|
      insert_document("page-traffic_test", { rank_14: i }, id: "/path/#{i}", type: "page-traffic")
    end
    commit_index("page-traffic_test")
  end

  def generate_random_example(schema: "help_page", payload: {}, details: {}, excluded_fields: [], regenerate_if: ->(_example) { false }, retry_attempts: EXAMPLE_GENERATOR_RETRIES)
    # just in case RandomExample does not generate a type field

    payload[:document_type] ||= schema
    retry_attempts.times do
      random_example = GovukSchemas::RandomExample.for_schema(notification_schema: schema) do |hash|
        hash["locale"] = "en"
        hash.merge!(payload.stringify_keys)

        unless details.empty?
          document_details = hash["details"] || {}
          hash["details"] = document_details.merge(details.stringify_keys)
        end

        hash.delete_if { |k, _| excluded_fields.include?(k) }
        hash
      end

      return random_example unless regenerate_if.call(random_example)
    end
    raise RandomExampleError, "Could not generate example"
  end

  def capture_stdout
    old = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old
  end
end
