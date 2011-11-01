require 'sinatra'
require 'slimmer'
require 'erubis'

require_relative 'helpers'
require_relative 'config'

class SearchEngine
  def search(query)
    return [
      {:title => "TITLE1", :description => "DESCRIPTION", :format => "local_transaction", :link => "/URL"},
      {:title => "TITLE1.1", :description => "DESCRIPTION", :format => "guide", :link => "/URL", :additional_links => [
        {:title => "SUB TITLE 1", :link => "/SUBURL"},
        {:title => "SUB TITLE 2", :link => "/SUBURL"},
        {:title => "SUB TITLE 3", :link => "/SUBURL"}
      ]},
      {:title => "TITLE2", :description => "DESCRIPTION", :format => "answer", :link => "/URL"},
      {:title => "TITLE3", :description => "DESCRIPTION", :format => "local_transaction", :link => "/URL"},
      {:title => "TITLE4", :description => "DESCRIPTION", :format => "FORMAT", :link => "/URL"},
      {:title => "TITLE5", :description => "DESCRIPTION", :format => "FORMAT", :link => "/URL"},
      {:title => "TITLE6", :description => "DESCRIPTION", :format => "FORMAT", :link => "/URL"},
      {:title => "TITLE7", :description => "DESCRIPTION", :format => "FORMAT", :link => "/URL"},
      {:title => "TITLE8", :description => "DESCRIPTION", :format => "FORMAT", :link => "/URL"},
      {:title => "TITLE9", :description => "DESCRIPTION", :format => "FORMAT", :link => "/URL"},
      {:title => "TITLE10", :description => "DESCRIPTION", :format => "FORMAT", :link => "/URL"},
      {:title => "TITLE11", :description => "DESCRIPTION", :format => "FORMAT", :link => "/URL"},
      {:title => "TITLE12", :description => "DESCRIPTION", :format => "FORMAT", :link => "/URL"}
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
