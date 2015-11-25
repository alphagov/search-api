require "taxonomy_prototype/taxon_finder"

module Indexer
  class DocumentPreparer
    def initialize(client)
      @client = client
    end

    def prepared(doc_hash, popularities, is_content_index)
      if is_content_index
        doc_hash = prepare_popularity_field(doc_hash, popularities)
        doc_hash = prepare_format_field(doc_hash)
        doc_hash = prepare_tags_field(doc_hash)
        doc_hash = add_prototype_taxonomy(doc_hash)
      end

      doc_hash = prepare_if_best_bet(doc_hash)
      doc_hash
    end

  private
    def add_prototype_taxonomy(doc_hash)
      taxon = ::TaxonomyPrototype::TaxonFinder.find_by(slug: doc_hash["link"])
      if taxon
        doc_hash.merge("alpha_taxonomy" => taxon)
      else
        doc_hash
      end
    end

    def prepare_popularity_field(doc_hash, popularities)
      pop = 0.0
      unless popularities.nil?
        link = doc_hash["link"]
        pop = popularities[link]
      end
      doc_hash.merge("popularity" => pop)
    end

    def prepare_tags_field(doc_hash)
      Indexer::TagLookup.new.prepare_tags(doc_hash)
    end

    def prepare_format_field(doc_hash)
      if doc_hash["format"].nil?
        doc_hash.merge("format" => doc_hash["_type"])
      else
        doc_hash
      end
    end

    # If a document is a best bet, and is using the stemmed_query field, we
    # need to populate the stemmed_query_as_term field with a processed version
    # of the field.  This produces a representation of the best-bet query with
    # all words stemmed and lowercased, and joined with a single space.
    #
    # At search time, all best bets with at least one word in common with the
    # user's query are fetched, and the stemmed_query_as_term field of each is
    # checked to see if it is a substring match for the (similarly normalised)
    # user's query.  If so, the best bet is used.
    def prepare_if_best_bet(doc_hash)
      if doc_hash["_type"] != "best_bet"
        return doc_hash
      end

      stemmed_query = doc_hash["stemmed_query"]
      if stemmed_query.nil?
        return doc_hash
      end

      doc_hash["stemmed_query_as_term"] = " #{analyzed_best_bet_query(stemmed_query)} "
      doc_hash
    end

    # duplicated in index.rb
    def analyzed_best_bet_query(query)
      analyzed_query = JSON.parse(@client.get_with_payload(
        "_analyze?analyzer=best_bet_stemmed_match", query))

      analyzed_query["tokens"].map { |token_info|
        token_info["token"]
      }.join(" ")
    end
  end
end
