require "search/query_helpers"

module QueryComponents
  class CoreQuery < BaseComponent
    DEFAULT_QUERY_ANALYZER_WITHOUT_SYNONYMS = "default".freeze

    # Used with foo.synonym fields. Passing this is not necessary because
    # it's the default for these fields. We're only passing it at query time
    # to make the various possible queries more consistant with each other.
    QUERY_TIME_SYNONYMS_ANALYZER = "with_search_synonyms".freeze

    # Clause boosts for a search query
    MATCH_ALL_TITLE_BOOST = 10
    MATCH_ALL_ACRONYM_BOOST = 10
    MATCH_ALL_DESCRIPTION_BOOST = 5
    MATCH_ALL_CUSTOM_FIELDS_BOOST = 4
    MATCH_ALL_INDEXABLE_CONTENT_BOOST = 2
    MATCH_ALL_MULTI_BOOST = 0.5
    MATCH_ANY_MULTI_BOOST = 0.5
    MATCH_MINIMUM_BOOST = 0.5

    # If the search query is a single quoted phrase, we run a different query,
    # which uses phrase matching across various fields.
    # Boost title the most, but ensure that organisations rank brilliantly
    # for their acronym.
    PHRASE_MATCH_TITLE_BOOST = 5
    PHRASE_MATCH_ACRONYM_BOOST = 5
    PHRASE_MATCH_DESCRIPTION_BOOST = 2
    PHRASE_MATCH_CUSTOM_FIELDS = 1.5
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

    def mixed_quoted_unquoted_query
      quoted = search_params.parsed_query[:quoted].map { |query| quoted_phrase_query(query) }

      unquoted_query = search_params.parsed_query[:unquoted]
      unquoted = unquoted_phrase_query(unquoted_query)

      if quoted.empty?
        unquoted
      elsif unquoted_query.empty? && quoted.count == 1
        # TODO: check why this is in an array
        [quoted[0]]
      else
        # TODO: think about relative weightings here
        {
          bool: {
            must: quoted,
            should: unquoted,
          },
        }
      end
    end

    def quoted_phrase_query(query = search_term)
      # Return the highest weight found by looking for a phrase match in
      # individual fields
      dis_max_query(priority_fields_match_phrase(query))
    end

    def unquoted_phrase_query(query = search_term)
      all_field_boosts = priority_fields_match_all_terms(query).concat(
        [
          match_all_terms(priority_fields.keys, query, MATCH_ALL_MULTI_BOOST),
          match_any_terms(priority_fields.keys, query, MATCH_ANY_MULTI_BOOST),
          match_bigrams(priority_fields.keys, query, MATCH_ANY_MULTI_BOOST),
          minimum_should_match("all_searchable_text", query, MATCH_MINIMUM_BOOST),
        ],
      )

      should_coord_query(all_field_boosts.reject(&:empty?))
    end

    def priority_fields_match_all_terms(query)
      priority_fields.map { |field, boost| match_all_terms([field], query, boost) }
    end

    def priority_fields_match_phrase(query)
      priority_fields_quoted.map { |field, boost| match_phrase_default_analyzer(field, query, boost) }
    end

    def priority_fields
      {
        "title" => MATCH_ALL_TITLE_BOOST,
        "acronym" => MATCH_ALL_ACRONYM_BOOST,
        "description" => MATCH_ALL_DESCRIPTION_BOOST,
        "indexable_content" => MATCH_ALL_INDEXABLE_CONTENT_BOOST,
      }.merge(custom_priority_fields)
    end

    def priority_fields_quoted
      {
        "title.no_stop" => PHRASE_MATCH_TITLE_BOOST,
        "acronym.no_stop" => PHRASE_MATCH_ACRONYM_BOOST,
        "description.no_stop" => PHRASE_MATCH_DESCRIPTION_BOOST,
        "indexable_content.no_stop" => PHRASE_MATCH_INDEXABLE_CONTENT_BOOST,
      }.merge(custom_priority_fields(quoted: true))
    end

    def custom_priority_fields(quoted: false)
      search_params.boost_fields.each_with_object({}) do |field, hash|
        if quoted
          hash["#{field}.no_stop"] = PHRASE_MATCH_CUSTOM_FIELDS
        else
          hash[field] = MATCH_ALL_CUSTOM_FIELDS_BOOST
        end
      end
    end

    def minimum_should_match(field_name, query, boost = 1.0)
      {
        match: {
          synonym_field(field_name) => {
            boost:,
            query: escape(query),
            analyzer: query_analyzer,
            minimum_should_match: MINIMUM_SHOULD_MATCH,
          },
        },
      }
    end

    def match_phrase(field_name, query, boost = 1.0)
      {
        match_phrase: {
          synonym_field(field_name) => {
            boost:,
            query: escape(query),
            analyzer: query_analyzer,
          },
        },
      }
    end

    def match_all_terms(fields, query, boost = 1.0)
      fields = fields.map { |f| synonym_field(f) }

      {
        multi_match: {
          boost:,
          query: escape(query),
          operator: "and",
          fields:,
          analyzer: query_analyzer,
        },
      }
    end

    def match_any_terms(fields, query, boost = 1.0)
      fields = fields.map { |f| synonym_field(f) }

      {
        multi_match: {
          boost:,
          query: escape(query),
          operator: "or",
          fields:,
          analyzer: query_analyzer,
        },
      }
    end

    def match_bigrams(fields, query, boost = 1.0)
      return {} unless search_params.use_shingles?

      fields = fields.map { |f| "#{f}.shingles" }

      {
        multi_match: {
          boost:,
          query: escape(query),
          operator: "or",
          fields:,
          analyzer: "shingled_query_analyzer",
        },
      }
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
            boost:,
            query:,
          },
        },
      }
    end
  end
end
