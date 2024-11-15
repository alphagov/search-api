module Index
  class ElasticsearchProcessor
    def self.metasearch
      new(client: MetasearchIndex::Client)
    end

    def self.govuk
      new(client: GovukIndex::Client)
    end

    def self.specialist_document
      new(client: SpecialistDocumentIndex::Client)
    end

    def initialize(client:)
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
        body: @actions,
      )
    end
  end
end
