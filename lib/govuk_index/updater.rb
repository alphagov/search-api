module GovukIndex
  class Updater
    SCROLL_BATCH_SIZE = 500
    PROCESSOR_BATCH_SIZE = 100
    TIMEOUT_SECONDS = 30

    def self.update(index_name, job)
      new(
        source_index: index_name,
        destination_index: index_name,
        job: job,
      ).run
    end

    def initialize(source_index:, destination_index:, job:)
      @source_index = source_index
      @destination_index = destination_index
      @job = job
    end

    def run(async: true)
      Clusters.active.each do |cluster|
        scroll_enumerator(cluster:).each_slice(PROCESSOR_BATCH_SIZE) do |document_id|
          if async
            @job.perform_async(document_id, @destination_index)
          else
            @job.new.perform(document_id, @destination_index)
          end
        end
      end
    end

  private

    def search_body
      { query: { match_all: {} } }
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
