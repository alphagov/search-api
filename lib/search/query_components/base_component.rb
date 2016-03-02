module QueryComponents
  class BaseComponent
    include Search::Escaping

    attr_reader :search_params

    def initialize(search_params = Search::QueryParameters.new)
      @search_params = search_params
    end

    def search_term
      search_params.query
    end
  end
end
