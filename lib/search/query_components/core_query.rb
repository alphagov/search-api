require "search/query_helpers"

module QueryComponents
  class CoreQuery < BaseComponent
    DEFAULT_QUERY_ANALYZER = "query_with_old_synonyms".freeze

    # If the search query is a single quoted phrase, we run a different query,
    # which uses phrase matching across various fields.
    # Boost title the most, but ensure that organisations rank brilliantly
    # for their acronym.
    PHRASE_MATCH_TITLE_BOOST = 5
    PHRASE_MATCH_ACRONYM_BOOST = 5
    PHRASE_MATCH_DESCRIPTION_BOOST = 2
    PHRASE_MATCH_INDEXABLE_CONTENT_BOOST = 1

    include Search::QueryHelpers

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
    MINIMUM_SHOULD_MATCH = "2<2 3<3 7<50%".freeze

    def optional_id_code_query
      return nil unless search_params.enable_id_codes?

      # Return the highest weight obtained by searching for the text when
      # analyzed in different ways (with a small bonus if it matches in
      # multiple of these ways).
      queries = []
      queries << minimum_should_match("_all")
      queries << minimum_should_match_default_analyzer("all_searchable_text.id_codes", search_term, minimum_should_match: "1")

      dis_max_query(queries, tie_breaker: 0.1)
    end

    # FIXME: why is this wrapped in an array?
    def quoted_phrase_query
      # Return the highest weight found by looking for a phrase match in
      # individual fields
      [
        dis_max_query([
          minimum_should_match_default_analyzer("title.no_stop", search_params.query, type: :phrase, boost: PHRASE_MATCH_TITLE_BOOST),
          minimum_should_match_default_analyzer("acronym.no_stop", search_params.query, type: :phrase, boost: PHRASE_MATCH_ACRONYM_BOOST),
          minimum_should_match_default_analyzer("description.no_stop", search_params.query, type: :phrase, boost: PHRASE_MATCH_DESCRIPTION_BOOST),
          minimum_should_match_default_analyzer("indexable_content.no_stop", search_params.query, type: :phrase, boost: PHRASE_MATCH_INDEXABLE_CONTENT_BOOST)
        ])
      ]
    end

    def minimum_should_match_with_synonyms
      {
        match: {
          "all_searchable_text.synonym" => {
            query: escape(search_term),
            minimum_should_match: MINIMUM_SHOULD_MATCH,
          }
        }
      }
    end

    def minimum_should_match(field_name)
      {
        match: {
          field_name => {
            query: escape(search_term),
            analyzer: DEFAULT_QUERY_ANALYZER,
            minimum_should_match: MINIMUM_SHOULD_MATCH,
          }
        }
      }
    end

    def match_phrase(field_name)
      {
        match_phrase: {
          field_name => {
            query: escape(search_term),
            analyzer: DEFAULT_QUERY_ANALYZER,
          }
        }
      }
    end

    def match_all_terms(fields)
      {
        multi_match: {
          query: escape(search_term),
          operator: "and",
          fields: fields,
          analyzer: DEFAULT_QUERY_ANALYZER
        }
      }
    end

    def match_bigrams(fields)
      {
        multi_match: {
          query: escape(search_term),
          operator: "or",
          fields: fields,
          analyzer: "shingled_query_analyzer"
        }
      }
    end

  private

    # FIXME: this method is basically the same as #minimum_should_match, but
    # doesn't override the analyzer.
    # Boost is only used for quoted phrase queries.
    # Minimum should match is only used for the optional id code query
    # Operator doesn't seem to be used.
    def minimum_should_match_default_analyzer(field_name, query, type: :boolean, boost: 1.0, minimum_should_match: MINIMUM_SHOULD_MATCH, operator: :or)
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
