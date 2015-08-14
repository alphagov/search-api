module QueryComponents
  class Sort < BaseComponent
    # Get a list describing the sort order (or nil)
    def payload
      if search_params.order.nil?
        # Sort by popularity when there's no explicit ordering, and there's no
        # query (so there's no relevance scores).
        if search_term.nil? && !search_params.disable_popularity?
          return [{ "popularity" => { order: "desc" } }]
        else
          return nil
        end
      end

      field, order = search_params.order

      [{field => {order: order, missing: "_last"}}]
    end
  end
end
