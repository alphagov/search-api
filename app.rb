%w[ lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end

require 'sinatra'
require 'slimmer'
require 'erubis'
require 'json'

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

get "/autocomplete" do
  query = params['q'] or return '[]'
  results = settings.solr.complete(query)
  content_type :json
  JSON.dump(results.map { |r| r.to_hash })
end

post "/documents" do
  request.body.rewind
  [JSON.parse(request.body.read)].flatten.each do |hash|
    settings.solr.add Document.from_hash(hash)
  end
  content_type :json
  JSON.dump("result" => "OK")
end

post "/commit" do
  simple_json_result(settings.solr.commit)
end

delete "/documents/*" do
  simple_json_result(settings.solr.delete(params["splat"].first))
end
