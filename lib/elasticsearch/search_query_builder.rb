require "elasticsearch/escaping"

module Elasticsearch
  class SearchQueryBuilder
    include Elasticsearch::Escaping

    QUERY_ANALYZER = "query_with_old_synonyms"

    # `query`    - a string to search for
    # `mappings` - the field definitions for the index this query is going to
    #              used to validate parts of the query before sending to
    #              Elasticsearch. The format is as follows:
    #                {
    #                  "edition" => {
    #                    "_all" => { "enabled" => true },
    #                    "properties" => {
    #                       "fieldname" => { ...field definition... }
    #                    }
    #                  }
    #                }
    # `options`  - a hash with symbol keys
    def initialize(query, mappings, options={})
      @query                = query
      @mappings             = mappings
      @limit                = options[:limit] || 50
      @sort                 = options[:sort]
      @order                = options[:order] || "desc"
      @organisation         = options[:organisation]
    end

    def query_hash
      {
        from: 0,
        size: @limit,
        query: {
          function_score: {
            query: {
              bool: {
                should: [core_query]
              }
            },
            functions: format_boosts + [time_boost]
          }
        },
        sort: sort
      }
    end

    def valid?
      error.empty?
    end

    def error
      errors = []
      if @sort && ! @mappings["edition"]["properties"].keys.include?(@sort)
        errors << "Sorting on unknown property: #{@sort}"
      end
      if @order && ! ["asc", "desc"].include?(@order)
        errors << "Unexpected ordering: #{@order}"
      end
      errors.flatten.join('. ')
    end

  private
    def sort
      if @sort
        [
          { @sort => { "order" => @order } }
        ]
      else
        []
      end
    end

    def core_query
      {
        bool: {
          must: must_conditions,
          should: should_conditions
        }
      }
    end

    def should_conditions
      exact_field_boosts + [ exact_match_boost, shingle_token_filter_boost ]
    end

    def exact_field_boosts
      match_fields.map {|field_name, _|
        {
          match_phrase: {
            field_name => {
              query: escape(@query),
              analyzer: QUERY_ANALYZER,
            }
          }
        }
      }
    end

    def exact_match_boost
      {
        multi_match: {
          query: escape(@query),
          operator: "and",
          fields: match_fields.keys,
          analyzer: QUERY_ANALYZER
        }
      }
    end

    def shingle_token_filter_boost
      {
        multi_match: {
          query: escape(@query),
          operator: "or",
          fields: match_fields.keys,
          analyzer: "shingled_query_analyzer"
        }
      }
    end

    def query_string_query
      {
        match: {
          _all: {
            query: escape(@query),
            analyzer: QUERY_ANALYZER,
            minimum_should_match: minimum_should_match
          }
        }
      }
    end

    def minimum_should_match
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
      "2<2 3<3 7<50%"
    end

    def organisation_query
      if @organisation
        {
          term: {
            organisations: @organisation
          }
        }
      end
    end

    def must_conditions
      [query_string_query, organisation_query].compact
    end

    def match_fields
      {
        "title" => 5,
        "acronym" => 5, # Ensure that organisations rank brilliantly for their acronym
        "description" => 2,
        "indexable_content" => 1,
      }
    end

    def boosted_formats
      {
        # Mainstream formats
        "smart-answer"      => 1.5,
        "transaction"       => 1.5,
        # Inside Gov formats
        "topical_event"     => 1.5,
        "minister"          => 1.7,
        "organisation"      => 2.5,
        "topic"             => 1.5,
        "document_series"   => 1.3,
        "document_collection" => 1.3,
        "operational_field" => 1.5,
      }
    end

    def format_boosts
      boosted_formats.map do |format, boost|
        {
          filter: { term: { format: format } },
          boost_factor: boost
        }
      end
    end

    # An implementation of http://wiki.apache.org/solr/FunctionQuery#recip
    # Curve for 2 months: http://www.wolframalpha.com/share/clip?f=d41d8cd98f00b204e9800998ecf8427e5qr62u0si
    #
    # Behaves as a freshness boost for newer documents with a public_timestamp and search_format_types announcement
    def time_boost
      {
        filter: { term: { search_format_types: "announcement" } },
        script_score: {
          script: "((0.05 / ((3.16*pow(10,-11)) * abs(now - doc['public_timestamp'].date.getMillis()) + 0.05)) + 0.12)",
          params: {
            now: time_in_millis_to_nearest_minute,
          },
        }
      }
    end

    def time_in_millis_to_nearest_minute
      (Time.now.to_i / 60) * 60000
    end
  end
end
