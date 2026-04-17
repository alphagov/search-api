module GovukIndex
  class PopularityUpdater < Updater
    def self.update(index_name)
      new(
        source_index: index_name,
        destination_index: index_name,
      ).run
    end

    def self.job
      PopularityJob
    end

    def initialize(source_index:, destination_index:)
      super(
        source_index:,
        destination_index:,
      )
    end

  private

    def search_body
      { query: { match_all: {} } }
    end
  end
end
