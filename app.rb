%w[ lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end

require 'sinatra'
require 'slimmer'
require 'erubis'

require 'document'
require 'solr_wrapper'

require_relative 'helpers'
require_relative 'config'

get "/search" do
  @query = params['q'] or return erb(:no_search_term)
  @results = settings.solr.search(@query)

  if @results.any?
    erb(:search)
  else
    erb(:no_search_results)
  end
end

post "/documents" do
  request.body.rewind
  hash = JSON.parse(request.body.read)
  document = Document.from_hash(hash)
  settings.solr.add document
end
