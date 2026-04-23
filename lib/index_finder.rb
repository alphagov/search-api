# Hides some of the dirtyness in selecting/generating the correct index objects
class IndexFinder
  class << self
    def by_name(index_name)
      search_server.index(index_name)
    end

    def search_config
      @search_config = SearchConfig.default_instance
    end

    def search_server
      @search_server = search_config.search_server
    end
  end
end
