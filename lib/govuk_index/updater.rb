module GovukIndex
  class Updater
    SCROLL_BATCH_SIZE = 500
    PROCESSOR_BATCH_SIZE = 100
    TIMEOUT_SECONDS = 30

    class ImplementationRequired < StandardError; end

    def initialize(source_index:, destination_index:)
      @source_index = source_index
      @destination_index = destination_index
    end

    def run(async: true)
      Clusters.active.each do |cluster|
        scroll_enumerator(cluster:).each_slice(PROCESSOR_BATCH_SIZE) do |document_id|
          if async
            job.perform_async(document_id, @destination_index)
          else
            job.new.perform(document_id, @destination_index)
          end
        end
      end
    end

    def self.job
      raise ImplementationRequired
    end

    def search_body
      raise ImplementationRequired
    end

  private

    def job
      self.class.job
    end

    def scroll_enumerator(cluster:)
      ScrollEnumerator.new(
        client: Services.elasticsearch(cluster:, timeout: TIMEOUT_SECONDS),
        index_names: @source_index,
        search_body:,
        batch_size: SCROLL_BATCH_SIZE,
      ) { |document| document["_id"] }
    end
  end
end
