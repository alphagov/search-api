module Indexer
  class AmendJob < BaseJob
    notify_of_failures

    def perform(index_name, document_link, updates, reschedule_on_failure: true)
      logger.info "Amending document '#{document_link}' in '#{index_name}'"
      logger.info "Amending fields #{updates.keys.join(', ')}"
      logger.debug "Amendments: #{updates}"
      begin
        indexes(index_name).each { |index| index.amend(document_link, updates) }
      rescue SearchIndices::IndexLocked => e
        if reschedule_on_failure
          logger.info "Index #{index_name} is locked; rescheduling"
          self.class.perform_in(LOCK_DELAY, index_name, document_link, updates)
        else
          raise e
        end
      end
    end
  end
end
