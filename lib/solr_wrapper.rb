require "document"
require "section"

class SolrWrapper
  HIGHLIGHT_START = "HIGHLIGHT_START"
  HIGHLIGHT_END   = "HIGHLIGHT_END"
  COMMIT_WITHIN = 5 * 60 * 1000 # 5m in ms

  def initialize(client, recommended_format)
    @client, @recommended_format = client, recommended_format
  end

  def add(documents)
    @client.update! documents.map(&:solr_export), commitWithin: COMMIT_WITHIN
  end

  def commit
    @client.commit!
  end

  def autocomplete_cache
    # TODO: Figure out the most popular or most queried for documents and
    # return them here.
    all_documents limit: 500
  end

  def all_documents options = {}
    options[:query] = escape(options[:query].downcase) if options[:query]
    query_opts = { query: '*:*', fields: "title,link,format", fq: "-format:#{@recommended_format}" }.merge options
    results = @client.query("standard", query_opts) or return []
    results.raw_response ? results.docs.map { |h| Document.from_hash(h) } : []
  end

  def search(q)
    results = @client.query("dismax",
      :query  => escape(q.downcase),
      :fields => "title,link,description,format,section,additional_links__title,additional_links__link,additional_links__link_order",
      :bq     => "format:#{@recommended_format}",
      :hl     => "true",
      "hl.fl" => "description,indexable_content",
      "hl.simple.pre"  => HIGHLIGHT_START,
      "hl.simple.post" => HIGHLIGHT_END,
      :limit  => 50
    )
    return [] unless results && results.raw_response

    results.docs.map{ |h| Document.from_hash(h).tap { |doc|
      doc.highlight = %w[ description indexable_content ].map { |f|
        (results.highlights_for(doc.link, f) || []).first
      }.compact.first
    }}
  end

  def section(q)
    results = @client.query("standard", :query => { :section => q }, :sort => "sortable_title asc", :fields => "*", :limit => 100) or return []
    results.raw_response ? results.docs.map{ |h| Document.from_hash(h) } : []
  end

  def facet(q)
    results = @client.query('standard', :query => "*:*", :facets => [{:field => q, :sort => q}]) or return []
    results.facet_field_values(q).reject{ |f| f.empty?  }.map{ |s| Section.new(s) }
  end

  def complete(q)
    results = @client.query("standard", query: "autocomplete:#{escape(q.downcase)}*", fq: "-format:#{@recommended_format}", fields: "title,link,format", limit: 10) or return []
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
