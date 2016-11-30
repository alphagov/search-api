require "gds_api/rummager"
require "json"
require_relative "../parameter_parser/base_parameter_parser"

class DataInconsistencyError < StandardError
end

desc "Check for and report any non-expanded facet values"
task :report_inconsistent_facet_values do
  # List of facets to check
  facets = BaseParameterParser::ALLOWED_FACET_FIELDS

  rummager = GdsApi::Rummager.new(Plek.new.find("rummager"))
  facet_values_to_report = {}

  facets.each do |facet|
    puts "Checking #{facet} facet..."
    facet_values_to_report[facet] = []

    # Return 1000 facet values by default and suppress actual results
    response = rummager.search({
      "facet_#{facet}" => 1000,
      "count" => 0
    })

    if response.code != 200
      puts "Error getting data for #{facet} facet: code #{response.code}"
      next
    end

    facet_values = response.to_hash.dig("facets", facet, "options")

    facet_values.each do |facet_value|
      if facet_value["value"].keys == ["slug"]
        # The facet value only contains a slug, therefore is not expanded
        puts " - \"#{facet_value["value"]["slug"]}\" is not expanded"
        facet_values_to_report[facet] << facet_value["value"]["slug"]
      end
    end
    puts

    if !facet_values_to_report[facet].empty?
      # Send the errors to Airbrake
      Airbrake.notify(DataInconsistencyError.new,
        error_message: "Some facet values for \"#{facet}\" are not expanded",
        parameters: {
          facet: facet,
          facet_values: facet_values_to_report[facet]
        }
      )
    end
  end
end
