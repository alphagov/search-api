module QueryComponents
  class Highlight < BaseComponent
    def payload
      {
        pre_tags: ['<em>'],
        post_tags: ['</em>'],
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
