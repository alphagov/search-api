module Indexer
  class BulkIndexFailure < RuntimeError
  end

  class FailedJobException < StandardError
  end

  class ProcessingError < StandardError
  end

  class UnknownDocumentError < ProcessingError
  end

  class MalformedMessage < ProcessingError
  end
end
