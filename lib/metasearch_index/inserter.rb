module MetasearchIndex
  module Inserter
    class V2
      class MissingArgument < StandardError; end
      class UnknownError < StandardError; end

      def initialize(id:, document:)
        @id = id.presence || raise(MissingArgument, "ID must be supplied.")
        @document = document.presence || raise(MissingArgument, "No record provided to insert into Elasticsearch.")
      end

      def insert
        processor = GovukIndex::ElasticsearchProcessor.new(client: MetasearchIndex::Client)
        processor.save(self)
        response = processor.commit
        validate_response!(response["items"].first)
      end

      def identifier
        {
          _type: 'best_bet',
          _id: @id,
        }
      end

      def document
        {
          exact_query: @document["exact_query"],
          stemmed_query: @document["stemmed_query"],
          stemmed_query_as_term: @document["stemmed_query_as_term"],
          details: @document["details"],
        }
      end

    private

      def validate_response!(response)
        action_type, details = response.first # response is a hash with a single [key, value] pair
        status = details['status']

        if (200..399).cover?(status)
          logger.debug("Processed #{action_type} with status #{status}")
          Services.statsd_client.increment("metasearch.elasticsearch.#{action_type}")
        else
          logger.error("#{action_type} not processed: status #{status}")
          Services.statsd_client.increment("metasearch.elasticsearch.#{action_type}_error")

          # manually send the error as we rescue it later in the process
          GovukError.notify(
            UnknownError.new,
            extra: {
              action_type: action_type,
              details: details,
            },
          )
          raise UnknownError, "Unknown Error"
        end
      end

      def logger
        Logging.logger[self]
      end
    end
  end
end
