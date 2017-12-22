module MetasearchIndex
  class Client < Index::Client
  private

    def index_name
      @_index ||= search_config.metasearch_index_name
    end
  end
end
