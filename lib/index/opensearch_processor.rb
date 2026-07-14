module Index
  class OpenSearchProcessor
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
