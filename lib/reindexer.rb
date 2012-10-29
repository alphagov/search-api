class Reindexer

  BATCH_SIZE = 50

  def initialize(backend, logger = nil)
    @backend = backend
    @logger = logger || Logger.new("/dev/null")
  end

  def reindex_all
    total_indexed = 0
    all_docs = @backend.all_documents(limit: 500000)
    all_docs.each_slice(BATCH_SIZE) do |documents|
      @backend.add documents
      total_indexed += documents.length
      @logger.info "Reindexed #{total_indexed} of #{all_docs.size}"
    end
  end
end
