module GovukIndex
  class SyncUpdater < Updater
    def self.update(destination_index: "govuk", source_index:)
      new(
        source_index: source_index,
        destination_index: destination_index,
      ).run
    end

    def self.update_immediately(destination_index: "govuk", format_override:, source_index:)
      new(
        source_index: source_index,
        destination_index: destination_index,
        format_override: format_override,
      ).run(async: false)
    end

    def self.worker
      SyncWorker
    end

    def initialize(source_index:, destination_index:, format_override: nil)
      super(
        source_index: source_index,
        destination_index: destination_index,
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
                format: Array(@format_override || MigratedFormats.indexable_formats.keys)
              }
            }
          }
        }
      }
    end
  end
end
