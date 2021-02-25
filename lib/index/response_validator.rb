module Index
  class ResponseValidator
    class NotFound < StandardError; end

    class ElasticsearchError < StandardError; end

    def initialize(namespace:)
      @namespace = namespace
    end

    def valid!(response)
      action_type, details = response.first # response is a hash with a single [key, value] pair
      status = details["status"]

      case status
      when 200..399
        logger.debug("Processed #{action_type} with status #{status}")
        Services.statsd_client.increment("#{@namespace}.elasticsearch.#{action_type}")
      when 404 # failed while attempting to delete missing record so just ignore it
        logger.info("Tried to delete a document that wasn't there; ignoring.")
        Services.statsd_client.increment("#{@namespace}.elasticsearch.already_deleted")
        raise NotFound, "Document not found in index"
      else
        logger.error("#{action_type} not processed: status #{status}")
        Services.statsd_client.increment("#{@namespace}.elasticsearch.#{action_type}_error")

        raise ElasticsearchError, "Unknown Error"
      end
    end

    def valid?(response)
      action_type, details = response.first # response is a hash with a single [key, value] pair
      status = details["status"]

      if (200..399).cover?(status)
        logger.debug("Processed #{action_type} with status #{status}")
        Services.statsd_client.increment("#{@namespace}.elasticsearch.#{action_type}")
      elsif action_type == "delete" && details["status"] == 404 # failed while attempting to delete missing record so just ignore it
        logger.info("Tried to delete a document that wasn't there; ignoring.")
        Services.statsd_client.increment("#{@namespace}.elasticsearch.already_deleted")
      elsif details["status"] == 409
        # A version conflict indicates that messages were processed out of
        # order. This is not expected to happen often but is safe to ignore.
        logger.info("#{action_type} version is outdated; ignoring.")
        Services.statsd_client.increment("#{@namespace}.elasticsearch.version_conflict")
      else
        logger.error("#{action_type} not processed: status #{status}")
        Services.statsd_client.increment("#{@namespace}.elasticsearch.#{action_type}_error")

        GovukError.notify(
          ElasticsearchError.new,
          extra: {
            action_type: action_type,
            details: details,
          },
        )
        return false
      end

      true
    end

    def logger
      Logging.logger[self]
    end
  end
end
