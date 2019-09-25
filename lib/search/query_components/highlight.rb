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
          },
          "title.synonym".to_sym => {
            number_of_fragments: 0,
          },
          description: {
            number_of_fragments: 1,
            fragment_size: 285,
          },
          "description.synonym".to_sym => {
            number_of_fragments: 1,
            fragment_size: 285,
          },
        }
      }
    end

  private

    def highlighted_field_requested?
      search_params.field_requested?("title_with_highlighting") ||
        search_params.field_requested?("description_with_highlighting")
    end
  end
end
