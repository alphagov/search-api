require "elasticsearch/escaping"

module Elasticsearch
  class SearchQueryBuilder
    include Elasticsearch::Escaping

    QUERY_ANALYZER = "query_default"

    def initialize(query, options={})
      @query = query
      @options = default_options.merge(options)
    end

    def default_options
      {
        limit: 50
      }
    end

    def default_minimum_should_match
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

    def query_hash
      {
        from: 0,
        size: @options[:limit],
        query: {
          custom_filters_score: {
            query: {
              bool: {
                should: [core_query, promoted_items_query].compact
              }
            },
            filters: format_boosts + [time_boost]
          }
        }
      }
    end

  private

    def core_query
      {
        bool: {
          must: must_conditions,
          should: shingle_boosts
        }
      }
    end

    def promoted_items_query
      {
        query_string: {
          default_field: "promoted_for",
          query: escape(@query),
          boost: 100
        }
      }
    end

    def query_string_query
      {
        query_string: {
          fields: match_fields.map { |name, boost|
            boost == 1 ? name : "#{name}^#{boost}"
          },
          query: escape(@query),
          analyzer: QUERY_ANALYZER
        }.merge(minimum_should_match_clause)
      }
    end

    def minimum_should_match_clause
      case @options[:minimum_should_match]
      when String, Fixnum
        {minimum_should_match: @options[:minimum_should_match]}
      when true
        {minimum_should_match: default_minimum_should_match}
      else
        {}
      end
    end

    def organisation_query
      if @options[:organisation]
        {
          term: {
            organisations: @options[:organisation]
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
        "description" => 2,
        "indexable_content" => 1,
      }
    end

    # "driving theory test" => ["driving theory", "theory test"]
    def shingles
      @query.split.each_cons(2).map { |s| s.join(' ') }
    end

    def shingle_boosts
      shingles.map do |shingle|
        match_fields.map do |field_name, _|
          {
            text: {
              field_name => {
                query: shingle,
                type: "phrase",
                boost: 2,
                analyzer: QUERY_ANALYZER
              },
            }
          }
        end
      end
    end

    def boosted_formats
      {
        # Mainstream formats
        "smart-answer"      => 2.2,
        "transaction"       => 2.3,
        # Inside Gov formats
        "topical_event"     => 1.5,
        "minister"          => 1.7,
        "organisation"      => 2.0,
        "topic"             => 1.5,
        "document_series"   => 1.3,
        "operational_field" => 1.5,
      }
    end

    def format_boosts
      boosted_formats.map do |format, boost|
        {
          filter: { term: { format: format } },
          boost: boost
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
        script: "((0.05 / ((3.16*pow(10,-11)) * abs(time() - doc['public_timestamp'].date.getMillis()) + 0.05)) + 0.12)"
      }
    end
  end
end
