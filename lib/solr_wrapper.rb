require "document"

class SolrWrapper
  COMMIT_WITHIN = 5 * 60 * 1000 # 5m in ms

  def initialize(client)
    @client = client
  end

  def add(document)
    @client.update! document.solr_export, commitWithin: COMMIT_WITHIN
  end

  def commit
    @client.commit!
  end

  def search(q)
    results = @client.query("standard", query: q, fields: "*") or return []
    results.docs.map{ |h| Document.from_hash(h) }
  end
end
