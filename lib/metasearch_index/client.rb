module MetasearchIndex
  class Client < Index::Client
    class << self
      delegate :analyze, to: :instance
    end

    def analyze(query:, analyzer:)
      ElasticsearchClient.analyze(query:, index_name:, analyzer:, client:)
    end

  private

    def index_name
      # rubocop:disable Naming/MemoizedInstanceVariableName
      @_index ||= SearchConfig.metasearch_index_name
      # rubocop:enable Naming/MemoizedInstanceVariableName
    end
  end
end
