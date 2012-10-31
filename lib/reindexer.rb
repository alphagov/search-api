class Reindexer

  BATCH_SIZE = 50

  def initialize(backend, logger = nil)
    @backend = backend
    @logger = logger || Logger.new("/dev/null")
  end

  def reindex_all
    total_indexed = 0
    # This will load the entire content of the search index into memory at
    # once, which isn't yet a big deal but may become a problem as the search
    # index grows. One alternative could be to use elasticsearch scan queries
    # <http://www.elasticsearch.org/guide/reference/api/search/search-type.html>
    all_docs = @backend.all_documents
    all_docs.each_slice(BATCH_SIZE) do |documents|
      @backend.add documents
      total_indexed += documents.length
      @logger.info "Reindexed #{total_indexed} of #{all_docs.size}"
    end
  end
end
