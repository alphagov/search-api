module QueryComponents
  class TextQuery < BaseComponent
    DEFAULT_QUERY_ANALYZER = "query_with_old_synonyms"
    DEFAULT_QUERY_ANALYZER_WITHOUT_SYNONYMS = 'default'

    # TODO: The `score` here doesn't actually do anything.
    MATCH_FIELDS = {
      "title" => 5,
      "acronym" => 5, # Ensure that organisations rank brilliantly for their acronym
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
      [query_string_query]
    end

    def should_conditions
      exact_field_boosts + [ exact_match_boost, shingle_token_filter_boost ]
    end

    def query_string_query
      {
        match: {
          _all: {
            query: escape(search_term),
            analyzer: query_analyzer,
            minimum_should_match: MINIMUM_SHOULD_MATCH,
          }
        }
      }
    end

    def exact_field_boosts
      MATCH_FIELDS.map do |field_name, _|
        {
          match_phrase: {
            field_name => {
              query: escape(search_term),
              analyzer: query_analyzer,
            }
          }
        }
      end
    end

    def exact_match_boost
      {
        multi_match: {
          query: escape(search_term),
          operator: "and",
          fields: MATCH_FIELDS.keys,
          analyzer: query_analyzer
        }
      }
    end

    def shingle_token_filter_boost
      {
        multi_match: {
          query: escape(search_term),
          operator: "or",
          fields: MATCH_FIELDS.keys,
          analyzer: "shingled_query_analyzer"
        }
      }
    end

    def query_analyzer
      if debug[:disable_synonyms]
        DEFAULT_QUERY_ANALYZER_WITHOUT_SYNONYMS
      else
        DEFAULT_QUERY_ANALYZER
      end
    end
  end
end
