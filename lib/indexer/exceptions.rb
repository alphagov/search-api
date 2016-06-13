module Indexer
  class BulkIndexFailure < RuntimeError
  end

  class FailedJobException < StandardError
  end

  class ProcessingError < StandardError
  end
end
