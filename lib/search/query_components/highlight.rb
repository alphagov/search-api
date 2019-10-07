module QueryComponents
  class Highlight < BaseComponent
    def payload
      return unless highlighted_field_requested?

      {
        pre_tags: ["<mark>"],
        post_tags: ["</mark>"],
        encoder: "html",
        fields: {
          title: {
            number_of_fragments: 0,
            highlight_query: highlight_query(:title),
          },
          "title.synonym".to_sym => {
            number_of_fragments: 0,
            highlight_query: highlight_query("title.synonym".to_sym),
          },
          description: {
            number_of_fragments: 1,
            fragment_size: 285,
            highlight_query: highlight_query(:description),
          },
          "description.synonym".to_sym => {
            number_of_fragments: 1,
            fragment_size: 285,
            highlight_query: highlight_query("description.synonym".to_sym),
          },
        },
      }
    end

  private

    def highlighted_field_requested?
      search_params.field_requested?("title_with_highlighting") ||
        search_params.field_requested?("description_with_highlighting")
    end

    def highlight_query(field)
      components = quoted.map { |q| { match_phrase: { field => { query: q } } } }
      components << { match: { field => { query: unquoted } } }

      { bool: { should: components } }
    end

    def quoted
      @quoted ||= search_params.parsed_query[:quoted] || []
    end

    def unquoted
      @unquoted ||= search_params.parsed_query[:unquoted] || ""
    end
  end
end
