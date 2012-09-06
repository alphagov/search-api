%w[ lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end

require 'sinatra'
require 'slimmer'
require 'erubis'
require 'json'
require 'csv'

require 'popular_items'
require 'document'
require 'section'
require 'utils'
require 'solr_wrapper'
require 'elasticsearch_wrapper'
require 'null_backend'
require 'slimmer_headers'
require 'sinatra/content_for'


require_relative 'config'
require_relative 'helpers'
require_relative 'backends'

def backends
  @backends ||= Backends.new(settings, logger)
end

def primary_search
  backends.primary_search
end

def secondary_search
  backends.secondary_search
end

helpers do
  include Helpers
end

before do
  headers SlimmerHeaders.headers(settings.slimmer_headers)
end

def prefixed_path(path)
  path_prefix = settings.router[:path_prefix]
  raise "Path prefix must start with /" unless path_prefix.blank? || path_prefix =~ /^\//
  "#{path_prefix}#{path}"
end

get prefixed_path("/search.?:format?") do
  @query = params["q"].to_s.gsub(/[\u{0}-\u{1f}]/, "").strip

  if @query == ""
    expires 3600, :public
    @page_section = "Search"
    @page_section_link = "/search"
    @page_title = "Search | GOV.UK Beta (Test)"
    return erb(:no_search_term)
  end

  expires 3600, :public if @query.length < 20

  results = primary_search.search(@query, params["format_filter"])
  secondary_results = secondary_search.search(@query)

  logger.info "Found #{secondary_results.count} secondary results"

  @secondary_results = secondary_results.take(5)
  @more_secondary_results = secondary_results.length > 5
  @results = results.take(50 - @secondary_results.length)
  @total_results = @results.length + @secondary_results.length

  if request.accept.include?("application/json") or params['format'] == 'json'
    content_type :json
    JSON.dump(@results.map { |r| r.to_hash.merge(
      highlight: r.highlight,
      presentation_format: r.presentation_format,
      humanized_format: r.humanized_format
    ) })
  else
    @page_section = "Search"
    @page_section_link = "/search"
    @page_title = "#{@query} | Search | GOV.UK Beta (Test)"

    headers SlimmerHeaders.headers(settings.slimmer_headers.merge(result_count: @results.length))

    if @results.any?
      erb(:search)
    else
      erb(:no_search_results)
    end
  end
end

get prefixed_path("/preload-autocomplete") do
  # Eventually this is likely to be a list of commonly searched for terms
  # so searching for those is really fast. For the beta, this is just a list
  # of all terms.
  expires 86400, :public
  content_type :json
  results = primary_search.autocomplete_cache rescue []
  JSON.dump(results.map { |r| r.to_hash })
end

get prefixed_path("/autocomplete") do
  content_type :json
  query = params['q']

  unless query
    expires 86400, :public
    return '[]'
  end

  expires 3600, :public if query.length < 5

  results = primary_search.complete(query, params["format_filter"]) rescue []
  JSON.dump(results.map { |r| r.to_hash.merge(
    presentation_format: r.presentation_format,
    humanized_format: r.humanized_format
  ) })
end

get prefixed_path("/sitemap.xml") do
  expires 86400, :public
  # Site maps can have up to 50,000 links in them.
  # We use one for / so we can have up to 49,999 others.
  documents = primary_search.all_documents limit: 49_999
  builder do |xml|
    xml.instruct!
    xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
      xml.url do
	xml.loc "#{base_url}#{prefixed_path("/")}"
      end
      documents.each do |document|
	xml.url do
	  url = document.link
          url = "#{base_url}#{url}" if url =~ /^\//
	  xml.loc url
	end
      end
    end
  end
end

if settings.router[:path_prefix].empty?
  get prefixed_path("/browse.?:format?") do
    headers SlimmerHeaders.headers(settings.slimmer_headers.merge(section: "Section nav"))
    expires 3600, :public
    @results = primary_search.facet('section')
    @page_title = "Browse | GOV.UK Beta (Test)"
    if request.accept.include?("application/json") or params['format'] == 'json'
      content_type :json
      JSON.dump(@results.map { |r| { url: "/browse/#{r.slug}" } })
    else
      erb(:sections)
    end
  end

  def assemble_section_details(section_slug)
    section = params[:section].gsub(/[^a-z0-9\-_]+/, '-')
    halt 404 unless section == params[:section]
    @ungrouped_results = primary_search.section(section)
    halt 404 if @ungrouped_results.empty?
    @section = Section.new(section)
    @page_section = formatted_section_name(@section.slug)
    @page_section_link = @section.path
    @results = @ungrouped_results.group_by { |result| result.subsection }.sort {|l,r| l[0].nil? ? 1 : l[0]<=>r[0]}
  end

  def compile_section_json(results)
    as_hash = {
      'name' => @page_section,
      'url' => @page_section_link,
      'contents' => []
    }
    description_path = File.expand_path("../views/_#{@section.slug}.html", __FILE__)

    if File.exists?(description_path)
      as_hash['description'] = File.read(description_path).gsub(/<\/?[^>]*>/, "")
    end

    @results.each do |subsection, items|
      as_hash['contents'] += items.collect do |i|
        { 'id' => i.link, 'title' => i.title, 'link' => i.link, 'format' => i.presentation_format, 'subsection' => subsection}
      end
    end
    as_hash
  end

  get prefixed_path("/browse/:section.json") do
    expires 86400, :public
    assemble_section_details(params[:section])
    content_type :json
    JSON.dump(compile_section_json(@results))
  end

  get prefixed_path("/browse/:section") do
    expires 86400, :public
    headers SlimmerHeaders.headers(settings.slimmer_headers.merge(section: "Section nav"))
    assemble_section_details(params[:section])

    if request.accept.include?("application/json")
      content_type :json
      JSON.dump(compile_json_for_section)
    else
      popular_items = PopularItems.new(settings.panopticon_api_credentials)
      @popular = popular_items.select_from(params[:section], @ungrouped_results)
      @sections = (primary_search.facet('section') || []).reject {|a| a.slug == @section.slug }
      @page_title = "#{formatted_section_name @section.slug} | GOV.UK Beta (Test)"
      erb(:section)
    end
  end
end

post prefixed_path("/documents") do
  request.body.rewind
  documents = [JSON.parse(request.body.read)].flatten.map { |hash|
    Document.from_hash(hash)
  }

  boosts = {}
  CSV.foreach(settings.boost_csv) { |row|
    link, phrases = row
    boosts[link] = phrases
  }

  better_documents = boost_documents(documents, boosts)

  simple_json_result(primary_search.add(better_documents))
end

post prefixed_path("/commit") do
  simple_json_result(primary_search.commit)
end

get prefixed_path("/documents/*") do
  document = primary_search.get(params["splat"].first)
  halt 404 unless document
  content_type :json
  JSON.dump document.to_hash
end

delete prefixed_path("/documents/*") do
  simple_json_result(primary_search.delete(params["splat"].first))
end

post prefixed_path("/documents/*") do
  def text_error(content)
    halt 403, {"Content-Type" => "text/plain"}, content
  end

  unless request.form_data?
    halt(
      415,
      {"Content-Type" => "text/plain"},
      "Amendments require application/x-www-form-urlencoded data"
    )
  end
  document = primary_search.get(params["splat"].first)
  halt 404 unless document
  text_error "Cannot change document links" if request.POST.include? 'link'

  # Note: this expects application/x-www-form-urlencoded data, not JSON
  request.POST.each_pair do |key, value|
    begin
      document.set key, value
    rescue NoMethodError
      text_error "Unrecognised field '#{key}'"
    end
  end
  simple_json_result(primary_search.add([document]))
end

delete prefixed_path("/documents") do
  if params['delete_all']
    action = primary_search.delete_all
  else
    action = primary_search.delete(params["link"])
  end
  simple_json_result(action)
end
