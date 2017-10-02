module GovukIndex
  class ElasticsearchProcessor
    def initialize(client: GovukIndex::Client)
      @client = client
      @actions = []
    end

    def raw(identifier, document)
      @actions << identifier
      @actions << document
    end

    def save(presenter)
      @actions << { index: presenter.identifier }
      @actions << presenter.document
    end

    def delete(presenter)
      @actions << { delete: presenter.identifier }
    end

    def commit
      return nil if @actions.empty?
      @client.bulk(
        body: @actions
      )
    end
  end
end
