module QueryComponents
  class Highlight < BaseComponent
    def payload
      {
        pre_tags: ['<mark>'],
        post_tags: ['</mark>'],
        encoder: 'html',
        fields: {
          title: {
            number_of_fragments: 0,
          },
          description: {
            number_of_fragments: 1,
            fragment_size: 285,
          },
        }
      }
    end
  end
end
