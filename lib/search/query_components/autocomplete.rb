module QueryComponents
  class Autocomplete < BaseComponent
    AUTOCOMPLETE_FIELD = "title.edgengram".freeze

    def payload
      {
        "bool" => {
          "must" => {
            "match" => {
              AUTOCOMPLETE_FIELD => {
                "query" => search_term,
                "operator" => "and",
              },
            },
          },
          "must_not" => {
            # The below are excluded from any autocomplete suggestions
            # If modified remember to update autocomplete_spec!
            "terms" => {
              "format" => [
                #As referenced from config/govuk_index/mapped_document_types.yaml
                "hmrc_manual_section",
                "dfid_research_output",
                "employment_tribunal_decision",
                "employment_appeal_tribunal_decision",
              ],
            },
          },
        },
      }
    end
  end
end
