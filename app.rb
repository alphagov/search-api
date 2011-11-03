%w[ lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end

require 'sinatra'
require 'slimmer'
require 'erubis'

require 'document'


require_relative 'helpers'
require_relative 'config'

class SearchEngine
  def search(query)
    return [
      Document.from_hash({"title" => "TITLE1", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
      Document.from_hash({"title" => "TITLE1.1", "description" => "DESCRIPTION", "format" => "guide", "link" => "/URL", "additional_links" => [
        {"title" => "SUB TITLE 1", "link" => "/SUBURL"},
        {"title" => "SUB TITLE 2", "link" => "/SUBURL"},
        {"title" => "SUB TITLE 3", "link" => "/SUBURL"}
      ]}),
      Document.from_hash({"title" => "TITLE2", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
      Document.from_hash({"title" => "TITLE3", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
      Document.from_hash({"title" => "TITLE4", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
      Document.from_hash({"title" => "TITLE5", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
      Document.from_hash({"title" => "TITLE6", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
      Document.from_hash({"title" => "TITLE7", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
      Document.from_hash({"title" => "TITLE8", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
      Document.from_hash({"title" => "TITLE9", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
      Document.from_hash({"title" => "TITLE10", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
      Document.from_hash({"title" => "TITLE11", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
      Document.from_hash({"title" => "TITLE12", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
      Document.from_hash({"title" => "TITLE13", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
      Document.from_hash({"title" => "TITLE14", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
      Document.from_hash({"title" => "TITLE15", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
      Document.from_hash({"title" => "TITLE16", "description" => "DESCRIPTION", "format" => "local_transaction", "link" => "/URL"}),
    ]
  end

end

get "/search" do
  @query = params['q']
  @results = SearchEngine.new().search(@query)
  if @query.nil?
    erb :no_search_term
  elsif @results.empty?
    erb :no_search_results
  else
    erb :search
  end
end
