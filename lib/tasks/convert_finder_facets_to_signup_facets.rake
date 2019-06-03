require 'open-uri'
require 'json'
require 'yaml'

desc "Converts facet from a finder content item to facets for a signup content item"
task :convert_finder_facets_to_signup_facets, [:base_url, :destination_file] do |_, args|
  content_item = JSON.parse(open('https://www.gov.uk/api/content/' + args[:base_url]).read)
  email_filter_facets = []
  content_item["links"]["facet_group"].each do |facet_group|
    facet_group["links"]["facets"].each do |facet|
      choices = facet["links"]["facet_values"].map do |facet_value|
        {
          "key" => facet_value["details"]["value"],
          "radio_button_name" => facet_value["details"]["label"],
          "topic_name" => facet_value["details"]["label"],
          "prechecked" => false,
        }
      end
      email_filter_facets << {
        "facet_id" => facet["details"]["key"],
        "facet_name" => facet["details"]["name"],
        "facet_choices" => choices,
      }
    end
  end
  File.open(args[:destination_file],"w") do |file|
    file.write email_filter_facets.to_yaml
  end
end
