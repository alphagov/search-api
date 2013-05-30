require 'search_config'

class LocalSearchClient
  def initialize(options={})
    @index_name          = options[:index] || "mainstream"
    @index = SearchConfig.new.search_server.index(@index_name)
  end

  def search(term)
    extract_results(@index.search(term))
  end

private
  def extract_results(result_set)
    result_set.results.map { |r| r.link }
  end
end
