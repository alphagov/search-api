module MetasearchIndex
  class Client < Index::Client
    class << self
      delegate :analyze, to: :instance
    end

    def analyze(params)
      client.indices.analyze(
        index: index_name,
        body: params,
      )
    end

  private

    def index_name
      @_index ||= SearchConfig.metasearch_index_name
    end
  end
end
