%w[ lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end

require 'sinatra'
require 'slimmer'
require 'erubis'
require 'json'

require 'document'
require 'section'
require 'solr_wrapper'
require 'slimmer_headers'

require_relative 'helpers'
require_relative 'config'

before do
  headers SlimmerHeaders.headers(
    section:     "Search",
    format:      "search",
    proposition: "citizen"
  )
end


def prefixed_path(path)
  path_prefix = settings.router[:path_prefix]
  "#{path_prefix}#{path}"
end

get prefixed_path("/search") do
  @query = params['q'] or return erb(:no_search_term)
  @results = settings.solr.search(@query)

  @page_section = "Search"
  @page_section_link = "/search"
  @page_title = "#{@query} | Search | GOV.UK"

  if @results.any?
    erb(:search)
  else
    erb(:no_search_results)
  end
end

get prefixed_path("/autocomplete") do
  query = params['q'] or return '[]'
  results = settings.solr.complete(query) rescue []
  content_type :json
  JSON.dump(results.map { |r| r.to_hash })
end

if settings.router[:path_prefix].empty?
  get prefixed_path("/browse") do
    @results = settings.solr.facet('section')
    @page_section = "Browse"
    @page_section_link = "/browse"
    @page_title = "Browse | GOV.UK"
    erb(:sections)
  end

  get prefixed_path("/browse/:section") do
    section = params[:section].gsub(/[^a-z0-9\-_]+/, '-')
    halt 404 unless section == params[:section]
    @results = settings.solr.section(section)
    halt 404 if @results.empty?
    @section = Section.new(section)
    @page_section = @section.name
    @page_section_link = @section.path
    @page_title = "#{@section.name} | GOV.UK"
    erb(:section)
  end
end

post prefixed_path("/documents") do
  request.body.rewind
  documents = [JSON.parse(request.body.read)].flatten.map { |hash|
    Document.from_hash(hash)
  }
  simple_json_result(settings.solr.add(documents))
end

post prefixed_path("/commit") do
  simple_json_result(settings.solr.commit)
end

delete prefixed_path("/documents/*") do
  simple_json_result(settings.solr.delete(params["splat"].first))
end
