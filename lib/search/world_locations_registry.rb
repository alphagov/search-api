module Search
  class WorldLocationsRegistry < BaseRegistry
    def initialize
      @cache = fetch
    end

    def all
      @cache
    end

    def by_content_id(*)
      # This is implemented on BaseRegistry but should not be called
      # on WorldLocationsRegistry as content_ids are not provided.
      raise NotImplementedError
    end

    def [](slug)
      all.find { |o| o['slug'] == slug }
    end

  private

    def fetch
      data = Services.worldwide_api.world_locations.with_subsequent_pages
      if data
        data.map { |result|
          {
            'title' => result['title'],
            'slug' => result['details']['slug']
          }
        }
      end
    end
  end
end
