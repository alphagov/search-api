module QueryComponents
  class Autocomplete < BaseComponent
    AUTOCOMPLETE_FIELD = "autocomplete".freeze

    def payload
      {
        "suggested_autocomplete" => {
          "prefix" => search_term,
          "completion" => {
            "field" => AUTOCOMPLETE_FIELD,
            "size" => 10,
            "skip_duplicates" => true,
          },
        },
      }
    end
  end
end
