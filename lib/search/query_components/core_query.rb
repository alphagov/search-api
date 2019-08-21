require "search/query_helpers"

module QueryComponents
  class CoreQuery < BaseComponent
    DEFAULT_QUERY_ANALYZER_WITHOUT_SYNONYMS = "default".freeze

    # Used with foo.synonym fields. Passing this is not necessary because
    # it's the default for these fields. We're only passing it at query time
    # to make the various possible queries more consistant with each other.
    QUERY_TIME_SYNONYMS_ANALYZER = "with_search_synonyms".freeze

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

    # FIXME: why is this wrapped in an array?
    def quoted_phrase_query
      # Return the highest weight found by looking for a phrase match in
      # individual fields
      [
        dis_max_query([
          match_phrase_default_analyzer("title.no_stop", search_params.query, PHRASE_MATCH_TITLE_BOOST),
          match_phrase_default_analyzer("acronym.no_stop", search_params.query, PHRASE_MATCH_ACRONYM_BOOST),
          match_phrase_default_analyzer("description.no_stop", search_params.query, PHRASE_MATCH_DESCRIPTION_BOOST),
          match_phrase_default_analyzer("indexable_content.no_stop", search_params.query, PHRASE_MATCH_INDEXABLE_CONTENT_BOOST)
        ])
      ]
    end

    def unquoted_phrase_query
      should_coord_query([
        match_phrase("title", PHRASE_MATCH_TITLE_BOOST),
        match_phrase("acronym", PHRASE_MATCH_ACRONYM_BOOST),
        match_phrase("description", PHRASE_MATCH_DESCRIPTION_BOOST),
        match_phrase("indexable_content", PHRASE_MATCH_INDEXABLE_CONTENT_BOOST),
        match_all_terms(%w(title acronym description indexable_content)),
        match_any_terms(%w(title acronym description indexable_content), 0.2),
        minimum_should_match("all_searchable_text", 0.2)
      ])
    end

    # score = sum(clause_scores) * num(matching_clauses) / num(clauses)
    def should_coord_query(queries)
      {
        function_score: {
          query: { bool: { should: queries } },
          score_mode: "sum",
          boost_mode: "multiply",
          functions: queries.map do |q|
            {
              filter: q,
              weight: 1.0 / queries.length
            }
          end
        }
      }
    end

    def minimum_should_match(field_name, boost = 1.0)
      {
        match: {
          synonym_field(field_name) => {
            boost: boost,
            query: escape(search_term),
            analyzer: query_analyzer,
            minimum_should_match: MINIMUM_SHOULD_MATCH,
          }
        }
      }
    end

    def match_phrase(field_name, boost = 1.0)
      {
        match_phrase: {
          synonym_field(field_name) => {
            boost: boost,
            query: escape(search_term),
            analyzer: query_analyzer,
          }
        }
      }
    end

    def match_all_terms(fields, boost = 1.0)
      fields = fields.map { |f| synonym_field(f) }

      {
        multi_match: {
          boost: boost,
          query: escape(search_term),
          operator: "and",
          fields: fields,
          analyzer: query_analyzer
        }
      }
    end

    def match_any_terms(fields, boost = 1.0)
      fields = fields.map { |f| synonym_field(f) }

      {
        multi_match: {
          boost: boost,
          query: escape(search_term),
          operator: "or",
          fields: fields,
          analyzer: query_analyzer,
        }
      }
    end

    # Use the synonym variant of the field unless we're disabling synonyms
    def synonym_field(field_name)
      return field_name if search_params.disable_synonyms?

      raise ValueError if field_name.include?(".")

      field_name + ".synonym"
    end

  private

    def query_analyzer
      if search_params.disable_synonyms?
        # this is the default defined in the mapping for regular fields
        DEFAULT_QUERY_ANALYZER_WITHOUT_SYNONYMS
      else
        # this is the default defined in the mapping for *.synonym fields
        QUERY_TIME_SYNONYMS_ANALYZER
      end
    end

    def match_phrase_default_analyzer(field_name, query, boost)
      {
        match_phrase: {
          field_name => {
            boost: boost,
            query: query,
          }
        }
      }
    end
  end
end
