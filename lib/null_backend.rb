require "logger"

class NullBackend
  # A dummy backend for instances where secondary search is not in use.
  # NOTE: since we no longer have a concept of secondary search, this class is
  # deprecated and will be removed in a future release.

  def initialize(logger = nil)
    @logger = logger || Logger.new("/dev/null")
  end

  def all_documents(options = {})
    @logger.debug "Retrieving all documents from null backend"
    []
  end

  def search(q, format = nil)
    if format
      @logger.debug "Searching null backend for #{format} documents matching #{q}"
    else
      @logger.debug "Searching null backend for documents matching #{q}"
    end
    []
  end

  def get(link)
    @logger.debug 'Getting document with link "#{link}" from null backend'
    nil
  end
end
