module QueryComponents
  class Sort < BaseComponent
    # Get a list describing the sort order (or nil)
    def payload
      if search_params.order.nil?
        # Disable sorting when searching for "similar" documents because these
        # are already sorted in order of "similarity".
        if !search_params.similar_to.nil?
          return nil
        # Sort by popularity when there's no explicit ordering, and there's no
        # query (so there's no relevance scores).
        elsif search_term.nil? && !search_params.disable_popularity?
          return [{ "popularity" => { order: "desc" } }]
        else
          return nil
        end
      end

      field, order = search_params.order

      [
        {
          field => {
            order: order,
            missing: "_last",
            # not all indices have all fields, so if the field is
            # missing treat it as an integer (any type would work,
            # really) with a missing value.
            unmapped_type: "integer"
          }
       }
      ]
    end
  end
end
