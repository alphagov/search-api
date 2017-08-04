module QueryComponents
  class VisibilityFilter < BaseComponent
    include Search::QueryHelpers

    def rejected_queries
      return [] if search_params.debug[:include_withdrawn]

      [term_filter("is_withdrawn", true)]
    end
  end
end
