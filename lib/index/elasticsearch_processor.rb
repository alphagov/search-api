module Index
  class ElasticsearchProcessor
    def self.metasearch
      new(client: MetasearchIndex::Client)
    end

    def self.govuk
      new(client: GovukIndex::Client)
    end

    def initialize(client:)
      @client = client
      @actions = []
    end

    def raw(identifier, document)
      @actions << identifier
      @actions << ElasticsearchClient.compatible_identifier(document)
    end

    def save(presenter)
      @actions << { index: presenter.identifier }
      @actions << ElasticsearchClient.compatible_identifier(presenter.document)
    end

    def delete(presenter)
      @actions << { delete: ElasticsearchClient.compatible_identifier(presenter.identifier) }
    end

    def commit
      return nil if @actions.empty?

      @client.bulk(
        body: @actions,
      )
    end
  end
end
