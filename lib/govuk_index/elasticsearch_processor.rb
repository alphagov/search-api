module GovukIndex
  class ElasticsearchProcessor
    def initialize
      @actions = []
    end

    def save(presenter)
      @actions << { index: presenter.identifier }
      @actions << presenter.document
    end

    def delete(presenter)
      @actions << { delete: presenter.identifier }
    end

    def commit
      return if @actions.empty?
      GovukIndex::Client.bulk(
        body: @actions
      )
    end
  end
end
