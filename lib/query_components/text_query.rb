module QueryComponents
  class TextQuery < BaseComponent
    # Fields that we want to do a field-specific match for, together with a
    # boost value used for that match.
    MATCH_FIELDS = {
      "title" => 5,
      "acronym" => 5,
      "description" => 2,
      "indexable_content" => 1,
    }

    # Reference for the minimum_should_match syntax:
    # http://lucene.apache.org/solr/api-3_6_2/org/apache/solr/util/doc-files/min-should-match.html
    #
    # In summary, a clause of the form "N<M" means when there are MORE than N
    # clauses then M clauses should match. 2<-1 means when there are MORE than
    # 2 clauses then 1 may be missing.
    #
    # This configuration says that if there are 3-5 terms, allow one to be
    # missing; 6-7 terms, allow two to be missing, 8 more more terms, require
    # 75% present (rounded down).
    MINIMUM_SHOULD_MATCH = "2<-1 5<-2 7<75%"

    def payload
      if @search_params.quoted_search_phrase?
        payload_for_quoted_phrase
      else
        payload_for_unquoted_phrase
      end
    end

  private

    def payload_for_quoted_phrase
      groups = [field_boosts_phrase]
      dismax_groups(groups)
    end

    def payload_for_unquoted_phrase
      {
        bool: {
          must: must_conditions,
          should: should_conditions
        }
      }
    end

    def must_conditions
      [all_searchable_text_query]
    end

    def all_searchable_text_query
      # Return the highest weight obtained by searching for the text when
      # analyzed in different ways (with a small bonus if it matches in
      # multiple of these ways).
      queries = []
      queries << match_query(:all_searchable_text, search_term)

      unless search_params.disable_synonyms?
        queries << match_query(:"all_searchable_text.synonym", search_term)
      end

      queries << match_query(:"all_searchable_text.id_codes", search_term, minimum_should_match: "1")
      dis_max_query(queries, tie_breaker: 0.1)
    end

    def should_conditions
      groups = []
      groups << field_boosts_words
      groups << field_boosts_phrase
      groups << field_boosts_all_terms
      groups << field_boosts_synonyms unless search_params.disable_synonyms?
      groups << field_boosts_shingles
      groups << field_boosts_id_codes
      dismax_groups(groups)
    end

    def dismax_groups(groups)
      groups.map { |queries| dis_max_query(queries) }
    end

    def field_boosts_words
      # Return the highest weight found by looking for a word-based match in
      # individual fields
      MATCH_FIELDS.map { |field_name, boost|
        match_query("#{field_name}.no_stop", search_term, boost: boost)
      }
    end

    def field_boosts_phrase
      # Return the highest weight found by looking for a phrase match in
      # individual fields
      MATCH_FIELDS.map { |field_name, boost|
        match_query("#{field_name}.no_stop", search_term, type: :phrase, boost: boost)
      }
    end

    def field_boosts_all_terms
      # Return the highest weight found by looking for a match of all terms
      # individual fields
      MATCH_FIELDS.map { |field_name, boost|
        match_query("#{field_name}.no_stop", search_term, type: :boolean, operator: :and, boost: boost)
      }
    end

    def field_boosts_synonyms
      # Return the highest weight found by looking for a synonym-expanded word
      # match in individual fields
      MATCH_FIELDS.map { |field_name, boost|
        match_query("#{field_name}.synonym", search_term, boost: boost)
      }
    end

    def field_boosts_shingles
      # Return the highest weight found by looking for a shingle match in
      # individual fields
      MATCH_FIELDS.map { |field_name, boost|
        match_query("#{field_name}.shingles", search_term, boost: boost)
      }
    end

    def field_boosts_id_codes
      # Return the highest weight found by looking for an id_code match in
      # individual fields
      MATCH_FIELDS.map { |field_name, boost|
        match_query("#{field_name}.id_codes", search_term, minimum_should_match: "1", boost: boost)
      }
    end

    def dis_max_query(queries, tie_breaker: 0.0, boost: 1.0)
      # Calculates a score by running all the queries, and taking the maximum.
      # Adds in the scores for the other queries multiplied by `tie_breaker`.
      if queries.size == 1
        queries.first
      else
        {
          dis_max: {
            queries: queries,
            tie_breaker: tie_breaker,
            boost: boost,
          }
        }
      end
    end

    def match_query(field_name, query, type: :boolean, boost: 1.0, minimum_should_match: MINIMUM_SHOULD_MATCH, operator: :or)
      {
        match: {
          field_name => {
            type: type,
            boost: boost,
            query: query,
            minimum_should_match: minimum_should_match,
            operator: operator,
          }
        }
      }
    end
  end
end
