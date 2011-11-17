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

  def search_without_escaping(q)
    results = @client.query("standard", query: q, fields: "*") or return []
    results.docs.map{ |h| Document.from_hash(h) }
  end

  def search(q)
    search_without_escaping(escape(q.downcase))
  end

  def complete(q)
    search_without_escaping("autocomplete:#{escape(q.downcase)}*")
  end

  def delete(link)
    @client.delete_by_query("link:#{escape(link)}")
  end

  SOLR_SPECIAL_SEQUENCES = Regexp.new("(" + %w[
    + - && || ! ( ) { } [ ] ^ " ~ * ? : \\
  ].map { |s| Regexp.escape(s) }.join("|") + ")")

  def escape(s)
    s.gsub(SOLR_SPECIAL_SEQUENCES, "\\\\\\1")
  end
end
