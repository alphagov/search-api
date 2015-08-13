module QueryComponents
  class BaseComponent
    include Elasticsearch::Escaping

    attr_reader :search_params
    delegate :debug, to: :search_params

    def initialize(search_params = SearchParameters.new)
      @search_params = search_params
    end

    def search_term
      search_params.query
    end
  end
end
