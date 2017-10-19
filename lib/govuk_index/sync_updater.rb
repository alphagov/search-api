module GovukIndex
  class SyncUpdater < Updater
    def self.update(source_index: 'mainstream', destination_index: 'govuk')
      new(
        source_index: source_index,
        destination_index: destination_index,
      ).run
    end

    def self.update_immediately(source_index: 'mainstream', destination_index: 'govuk', format_override:)
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
      cause = @format_override ? :must : :must_not
      {
        query: {
          bool: {
            cause => {
              terms: {
                format: Array(@format_override || MigratedFormats.indexable_formats)
              }
            }
          }
        }
      }
    end
  end
end
