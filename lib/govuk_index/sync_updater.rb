module GovukIndex
  class SyncUpdater < Updater
    def self.update(source_index:, destination_index: "govuk")
      new(
        source_index:,
        destination_index:,
      ).run
    end

    def self.update_immediately(format_override:, source_index:, destination_index: "govuk")
      new(
        source_index:,
        destination_index:,
        format_override:,
      ).run(async: false)
    end

    def self.worker
      SyncWorker
    end

    def initialize(source_index:, destination_index:, format_override: nil)
      super(
        source_index:,
        destination_index:,
      )
      @format_override = format_override
    end

  private

    def search_body
      clause = @format_override ? :must : :must_not
      {
        query: {
          bool: {
            clause => {
              terms: {
                format: Array(@format_override || MigratedFormats.indexable_formats.keys),
              },
            },
          },
        },
      }
    end
  end
end
