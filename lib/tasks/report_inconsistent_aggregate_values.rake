require "gds_api/search"

class DataInconsistencyError < StandardError
end

desc "Check for and report any non-expanded aggregate values"
task :report_inconsistent_aggregate_values do
  # List of expandable aggregates
  # Same as in `lib/search/presenters/entity_expander.rb` minus
  # the content_id mappings which are not valid aggregate fields.
  aggregates = %w[
    document_series
    document_collections
    organisations
    policy_areas
    world_locations
    specialist_sectors
    people
  ]

  rummager = GdsApi::Search.new(Plek.new.find("search-api"))
  aggregate_values_to_report = {}

  aggregates.each do |aggregate|
    puts "Checking #{aggregate} aggregate..."
    aggregate_values_to_report[aggregate] = []

    # Return 1000 aggregate values by default and suppress actual results
    response = rummager.search({
      "aggregate_#{aggregate}" => 1000,
      "count" => 0,
    })

    if response.code != 200
      puts "Error getting data for #{aggregate} aggregate: code #{response.code}"
      next
    end

    aggregate_values = response.to_hash.dig("aggregates", aggregate, "options")

    aggregate_values.each do |aggregate_value|
      if aggregate_value["value"].keys == %w[slug]
        # The aggregate value only contains a slug, therefore is not expanded
        puts " - \"#{aggregate_value['value']['slug']}\" is not expanded"
        aggregate_values_to_report[aggregate] << aggregate_value["value"]["slug"]
      end
    end
    puts

    unless aggregate_values_to_report[aggregate].empty?
      # Send the errors to Sentry
      GovukError.notify(
        DataInconsistencyError.new,
        extra: {
          error_message: "Some aggregate values for \"#{aggregate}\" are not expanded",
          aggregate: aggregate,
          aggregate_values: aggregate_values_to_report[aggregate],
        },
      )
    end
  end
end

desc "Check for and report any non-expanded facet values [DEPRECATED]"
task report_inconsistent_facet_values: :report_inconsistent_aggregate_values do
  puts "[DEPRECATED] use `rake report_inconsistent_aggregate_values` instead"
end
