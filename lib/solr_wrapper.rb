require "document"
require "section"

class SolrWrapper
  COMMIT_WITHIN = 5 * 60 * 1000 # 5m in ms

  def initialize(client)
    @client = client
  end

  def add(documents)
    @client.update! documents.map(&:solr_export), commitWithin: COMMIT_WITHIN
  end

  def commit
    @client.commit!
  end

  def search_without_escaping(q)
    results = @client.query("dismax", query: q, fields: "*", bq: "format:#{settings.recommended_format}", limit: 50) or return []
    results.raw_response ? results.docs.map{ |h| Document.from_hash(h) } : []
  end

  def search(q)
    search_without_escaping(escape(q.downcase))
  end

  def section(q)
    results = @client.query("standard", :query => { :section => q }, :fields => "*", :limit => 100) or return []
    results.raw_response ? results.docs.map{ |h| Document.from_hash(h) } : []
  end

  def facet(q)
    results = @client.query('standard', :query => "*:*", :facets => [{:field => q, :sort => q}]) or return []
    results.facet_field_values(q).delete_if{ |f| f.empty?  }.map{ |s| Section.new(s) }
  end

  def complete(q)
    results = @client.query("standard", query: "autocomplete:#{escape(q.downcase)}*", fields: "title,link,format", limit: 10) or return []
    results.raw_response ? results.docs.map{ |h| Document.from_hash(h) } : []
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
