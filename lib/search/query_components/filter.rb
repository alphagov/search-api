require_relative "user_filter"
require_relative "visibility_filter"
require 'search/query_helpers'

module QueryComponents
  class Filter < BaseComponent
    include Search::QueryHelpers

    def payload(excluded_field_names = [])
      user_filter = QueryComponents::UserFilter.new(search_params)
      visibility_filter = QueryComponents::VisibilityFilter.new(search_params)

      user_rejected = combine_filters(
        user_filter.rejected_queries(excluded_field_names),
        :and
      )
      visibility_rejected = combine_filters(
        visibility_filter.rejected_queries,
        :and
      )
      all_rejected_queries = [user_rejected, visibility_rejected]

      # *all* filters must be true to *include* in the result
      selected = combine_filters(user_filter.selected_queries(excluded_field_names), :and)

      # *any* rejects can be true to *exclude* from the result
      rejected = combine_filters(all_rejected_queries, :or)

      if selected
        if rejected
          {
            bool: {
              must: selected,
              must_not: rejected,
            }
          }
        else
          selected
        end
      elsif rejected
        { not: rejected }
      end
    end
  end
end
