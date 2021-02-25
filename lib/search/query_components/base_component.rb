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

    # Use the synonym variant of the field unless we're disabling synonyms
    def synonym_field(field_name)
      return field_name if search_params.disable_synonyms?

      raise ValueError if field_name.include?(".")

      "#{field_name}.synonym"
    end
  end
end
