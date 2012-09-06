require "document"
require "section"
require "logger"

class SolrWrapper
  HIGHLIGHT_START = "HIGHLIGHT_START"
  HIGHLIGHT_END   = "HIGHLIGHT_END"
  COMMIT_WITHIN = 5 * 60 * 1000 # 5m in ms
  DOCUMENT_FIELDS = %w[
    title link description format section additional_links__title
    additional_links__link additional_links__link_order
  ]

  def initialize(client, recommended_format, logger=Logger.new('/dev/null'))
    @client, @recommended_format, @logger = client, recommended_format, logger
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

  def all_documents(options={})
    query_opts = {
      :query  => prepare_query(options[:query], "*:*"),
      :fields => "title,link,format",
      :fq     => "-format:#{@recommended_format}"
    }.merge(options)
    map_results(@client.query("standard", query_opts))
  end

  def search(q, format = nil)
    query_opts = {
      :query  => "#{prepare_query(q)}*",
      :fields => DOCUMENT_FIELDS.join(","),
      :bq     => "format:(transaction OR #{@recommended_format})^3.0",
      :hl     => "true",
      "hl.fl" => "description,indexable_content",
      "hl.simple.pre"  => HIGHLIGHT_START,
      "hl.simple.post" => HIGHLIGHT_END,
      :limit  => 50,
      :mm     => "75%"
    }
    query_opts[:fq] = "format:#{escape(format)}" if format
    map_results(@client.query("dismax", query_opts)) { |results, doc|
      doc.highlight = %w[ description indexable_content ].map { |f|
        results.highlights_for(doc.link, f)
      }.flatten.compact.first
    }
  end

  def get(link)
    map_results(@client.query("standard",
      :query  => "link:#{escape(link)}",
      :fields => "*",
      :limit  => 1
    )).first
  end

  def section(q)
    map_results(@client.query("standard",
      :query  => {:section => q},
      :sort   => "subsection asc, sortable_title asc",
      :fields => "*",
      :limit  => 120
    ))
  end

  def complete(q, format = nil)
    words = q.scan(/\S+/).map { |w| "autocomplete:#{prepare_query(w)}*" }
    params = {
      :query  => words.join(" "),
      :fields => "title,link,format",
      :limit  => 5,
      :fq => format ? "format:#{escape(format)}" : "-format:#{@recommended_format}"
    }
    map_results(@client.query("standard", params))
  end

  def delete(link)
    link = escape(link)
    log("Delete link: #{link}")
    @client.delete_by_query("link:#{link}")
  end

  def delete_all
    log("Deleting all documents in index!")
    @client.delete_by_query("link:[* TO *]")
    @client.commit!
    @client.optimize!
  end

  SOLR_SPECIAL_SEQUENCES = Regexp.new("(" + %w[
    + - && || ! ( ) { } [ ] ^ " ~ * ? : \\
  ].map { |s| Regexp.escape(s) }.join("|") + ")")

  def escape(s)
    s.gsub(SOLR_SPECIAL_SEQUENCES, "\\\\\\1")
  end

private
  def map_results(results)
    return [] unless results && results.raw_response
    results.docs.map{ |h| Document.from_hash(h).tap { |doc|
      yield(results, doc) if block_given?
    }}
  end

  def prepare_query(q, default="*:*")
    q ? escape(q).downcase : default
  end

  def log(message)
    @logger.info(message)
    message
  end
end
