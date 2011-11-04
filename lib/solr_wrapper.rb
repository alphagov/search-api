class SolrWrapper
  COMMIT_WITHIN = 5 * 60 * 1000 # 5m in ms

  def initialize(client)
    @client = client
  end

  def add(document)
    @client.update! document.solr_export, commitWithin: COMMIT_WITHIN
  end
end
