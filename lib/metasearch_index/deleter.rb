module MetasearchIndex
  module Deleter
    class V2
      class MissingArgument < StandardError; end
      class NotFound < StandardError; end
      class UnknownError < StandardError; end

      def initialize(id:)
        @id = id.presence || raise(MissingArgument, "ID and Type must be supplied.")
      end

      def delete
        processor = GovukIndex::ElasticsearchProcessor.new(client: MetasearchIndex::Client)
        processor.delete(self)
        response = processor.commit
        validate_response!(response['items'].first)
      end

      def identifier
        {
          _type: 'best_bet',
          _id: @id,
        }
      end

    private

      def validate_response!(response)
        action_type, details = response.first # response is a hash with a single [key, value] pair
        status = details['status']

        if (200..399).cover?(status)
          logger.debug("Processed #{action_type} with status #{status}")
          Services.statsd_client.increment("metasearch.elasticsearch.#{action_type}")
        elsif status == 404 # failed while attempting to delete missing record so just ignore it
          logger.info("Tried to delete a document that wasn't there; ignoring.")
          Services.statsd_client.increment('metasearch.elasticsearch.already_deleted')
          raise NotFound, "Document not found in index"
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
