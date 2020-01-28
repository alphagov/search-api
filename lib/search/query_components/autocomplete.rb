module QueryComponents
  class Autocomplete < BaseComponent
    AUTOCOMPLETE_FIELD = "autocomplete".freeze

    def payload
      {
        "suggested_autocomplete" => {
          "prefix" => search_term,
          "completion" => {
            "field" => AUTOCOMPLETE_FIELD,
            "size" => 8,
            "skip_duplicates" => true,
            "fuzzy" => {
              # For completion API we have to explicitly state this
              "fuzziness" => "AUTO",
            },
          },
        },
      }
    end
  end
end
