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

    # The following specification generates the following values for minimum_should_match
    #
    # Number of | Minimum
    # optional  | should
    # clauses   | match
    # ----------+---------
    # 1         | 1
    # 2         | 2
    # 3         | 2
    # 4         | 3
    # 5         | 3
    # 6         | 3
    # 7         | 3
    # 8+        | 50%
    #
    # This table was worked out by using the comparison feature of
    # bin/search with various example queries of different lengths (3, 4, 5,
    # 7, 9 words) and inspecting the consequences on search results.
    #
    # Reference for the minimum_should_match syntax:
    # http://lucene.apache.org/solr/api-3_6_2/org/apache/solr/util/doc-files/min-should-match.html
    #
    # In summary, a clause of the form "N<M" means when there are MORE than
    # N clauses then M clauses should match. So, 2<2 means when there are
    # MORE than 2 clauses then 2 should match.
    MINIMUM_SHOULD_MATCH = "2<2 3<3 7<50%"

    def payload
      {
        bool: {
          must: must_conditions,
          should: should_conditions
        }
      }
    end

  private

    def must_conditions
      [all_searchable_text_query]
    end

    def all_searchable_text_query
      # Return the highest weight obtained by searching for the text when
      # analyzed in different ways (with a small bonus if it matches in
      # multiple of these ways).
      queries = []
      queries << match_query(:all_searchable_text, search_term)
      queries << match_query(:"all_searchable_text.synonym", search_term) unless debug[:disable_synonyms]
      dis_max_query(queries, tie_breaker: 0.1)
    end

    def should_conditions
      groups = []
      groups << field_boosts_words
      groups << field_boosts_phrase
      groups << field_boosts_all_terms
      groups << field_boosts_synonyms unless debug[:disable_synonyms]

      groups.map { |queries|
        dis_max_query(queries)
      }
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

    def match_query(field_name, query, type: :boolean, boost: 1.0, operator: :or)
      {
        match: {
          field_name => {
            type: type,
            boost: boost,
            query: query,
            minimum_should_match: MINIMUM_SHOULD_MATCH,
            operator: operator,
          }
        }
      }
    end
  end
end
