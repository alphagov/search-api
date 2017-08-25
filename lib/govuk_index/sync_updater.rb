module GovukIndex
  class SyncUpdater < Updater
    def self.update(source_index: 'mainstream', destination_index: 'govuk')
      new(
        source_index: source_index,
        destination_index: destination_index,
      ).run
    end

  private

    def worker
      SyncWorker
    end

    def search_body
      {
        query: {
          bool: {
            must_not: {
              terms: {
                format: MigratedFormats.indexable_formats
              }
            }
          }
        }
      }
    end
  end
end
