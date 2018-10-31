module QueryComponents
  class Filter < BaseComponent
    include Search::QueryHelpers

    def payload(excluded_field_names = [])
      user_filter = QueryComponents::UserFilter.new(search_params)
      visibility_filter = QueryComponents::VisibilityFilter.new(search_params)

      rejected = user_filter.rejected_queries(excluded_field_names) + visibility_filter.rejected_queries

      selected = user_filter.selected_queries(excluded_field_names)

      result = {}
      result[:must] = selected unless selected.empty?
      result[:must_not] = rejected unless rejected.empty?
      result.empty? ? {} : { bool: result }
    end
  end
end
