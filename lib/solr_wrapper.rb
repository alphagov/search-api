class SolrWrapper
  def initialize(client)
    @client = client
  end

  def add(document)
    @client.update! document.solr_export
  end
end
