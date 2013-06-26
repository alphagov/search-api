require 'csv'

$LOAD_PATH << "./lib"
$LOAD_PATH << "./lib/elasticsearch"

require 'suggester'
require 'search_config'
require 'organisation_registry'

def lines_from_a_file(filepath)
  path = File.expand_path(filepath, File.dirname(__FILE__))
  lines = File.open(path).map(&:chomp)
  lines.reject { |line| line.start_with?('#') || line.empty? }
end

def ignores_from_file
  @@_ignores_from_file ||= lines_from_a_file("config/suggest/ignore.txt")
end

def blacklist_from_file
  @@_blacklist_from_file ||= lines_from_a_file("config/suggest/blacklist.txt")
end

def organisation_registry
  search_config = SearchConfig.new
  search_server = search_config.search_server
  OrganisationRegistry.new(search_server.index(search_config.organisation_registry_index))
end

Search = Struct.new(:term, :volume, :suggestion)
searches = {}

CSV.foreach("./top_terms.csv", headers: true) do |row|
  term = row["Search Term"].downcase
  frequency = row["Total Unique Searches"].delete(",").to_i #25,806

  search = searches[term] || searches[term] = Search.new(term, 0)
  search.volume = search.volume + frequency
end

org_acronyms = organisation_registry.all.map(&:acronym).reject(&:nil?)
ignore_list = org_acronyms + ignores_from_file

suggester = Suggester.new(ignore: ignore_list, blacklist: blacklist_from_file)
searches.each do |term, search|
  search.suggestion = suggester.suggestions(term).first
end

searches_with_suggestions = searches.reject { |term, search| search.suggestion.nil? }

csv_string = CSV.generate do |csv|
  csv << ["Volume", "Term", "Suggestion"]
  searches_with_suggestions.sort_by { |term, search| search.volume }.reverse.each do |term, search|
    csv << [search.volume, search.term, search.suggestion]
  end
end

puts csv_string