module Indexer
  class DocumentPreparer
    def initialize(client)
      @client = client
      @logger = Logging.logger[self]
    end

    def prepared(doc_hash, popularities, is_content_index)
      warn_if_links_present_in(doc_hash)
      if is_content_index
        doc_hash = copy_legacy_topic_to_policy_area(doc_hash)
        doc_hash = prepare_popularity_field(doc_hash, popularities)
        doc_hash = prepare_format_field(doc_hash)
        doc_hash = prepare_tags_field(doc_hash)
        doc_hash = add_self_to_organisations_links(doc_hash)
      end

      doc_hash = prepare_if_best_bet(doc_hash)
      doc_hash
    end

  private

    class UnexpectedLinksError < StandardError
    end

    def warn_if_links_present_in(doc_hash)
      unexpected_links = %w{ mainstream_browse_pages organisations specialist_sectors }
      if doc_hash.keys.any? { |key| unexpected_links.include?(key) }
        Airbrake.notify_or_ignore(UnexpectedLinksError.new, parameters: doc_hash)
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
      Indexer::LinksLookup.prepare_tags(doc_hash)
    end

    def prepare_format_field(doc_hash)
      if doc_hash["format"].nil?
        doc_hash.merge("format" => doc_hash["_type"])
      else
        doc_hash
      end
    end

    def copy_legacy_topic_to_policy_area(doc_hash)
      if doc_hash["topics"]
        doc_hash["policy_areas"] = doc_hash["topics"]
      end

      doc_hash
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
      analyzed_query = JSON.parse(
        @client.get_with_payload("_analyze?analyzer=best_bet_stemmed_match", query)
      )

      analyzed_query["tokens"].map { |token_info|
        token_info["token"]
      }.join(" ")
    end

    def add_self_to_organisations_links(doc_hash)
      # Consider an organisation page to linked to itself.
      # This means that when filtering on an organisation,
      # the organisation page gets included in the search results.
      #
      # This deliberately doesn't match up with the canonical representation
      # of the organisation in the publishing api, since self-linking has
      # a very fuzzy meaning: ids in links can mean both the thing (HMRC)
      # and the content representing the thing (the HMRC home page).
      if doc_hash["format"] == "organisation" && doc_hash["slug"]
        doc_hash["organisations"] ||= []
        doc_hash["organisations"] << doc_hash["slug"]
        doc_hash["organisations"].uniq!
      end

      doc_hash
    end
  end
end
