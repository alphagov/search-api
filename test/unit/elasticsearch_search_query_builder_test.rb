require "test_helper"
require "elasticsearch/search_query_builder"

class SearchQueryBuilderTest < MiniTest::Unit::TestCase
  def extract_condition_by_type(query_hash, condition_type)
    must_conditions = query_hash[:query][:custom_filters_score][:query][:bool][:must]
    must_conditions.find { |condition| condition.keys == [condition_type] }
  end

  def test_query_string_condition
    builder = Elasticsearch::SearchQueryBuilder.new("tomahawk")

    query_string_condition = extract_condition_by_type(builder.query_hash, :query_string)
    expected = {
      query_string: {
        fields: [
          "title^5",
          "description^2",
          "indexable_content"
        ],
        query: "tomahawk",
        analyzer: "query_default"
      }
    }
    assert_equal expected, query_string_condition
  end

  def test_shingle_boosts
    builder = Elasticsearch::SearchQueryBuilder.new("quick brown fox")
    shingle_boosts = builder.query_hash[:query][:custom_filters_score][:query][:bool][:should]
    expected = [
      [
        { text: { "title"             => { query: "quick brown", type: "phrase", boost: 2, analyzer: "query_default" }}},
        { text: { "description"       => { query: "quick brown", type: "phrase", boost: 2, analyzer: "query_default" }}},
        { text: { "indexable_content" => { query: "quick brown", type: "phrase", boost: 2, analyzer: "query_default" }}}
      ],
      [
        { text: { "title"             => { query: "brown fox",   type: "phrase", boost: 2, analyzer: "query_default" }}},
        { text: { "description"       => { query: "brown fox",   type: "phrase", boost: 2, analyzer: "query_default" }}},
        { text: { "indexable_content" => { query: "brown fox",   type: "phrase", boost: 2, analyzer: "query_default" }}}
      ]
    ]
    assert_equal expected, shingle_boosts
  end

  def test_format_boosts
    builder = Elasticsearch::SearchQueryBuilder.new("cherokee")
    filters = builder.query_hash[:query][:custom_filters_score][:filters]

    expected = [
      { filter: { term: { format: "smart-answer" } },      boost: 1.5 },
      { filter: { term: { format: "transaction" } },       boost: 1.5 },
      { filter: { term: { format: "topical_event" } },     boost: 1.5 },
      { filter: { term: { format: "minister" } },          boost: 1.7 },
      { filter: { term: { format: "organisation" } },      boost: 2.5 },
      { filter: { term: { format: "topic" } },             boost: 1.5 },
      { filter: { term: { format: "document_series" } },   boost: 1.3 },
      { filter: { term: { format: "operational_field" } }, boost: 1.5 },
    ]
    assert_equal expected, filters[0..-2]
  end

  def test_time_boost
    builder = Elasticsearch::SearchQueryBuilder.new("sioux")
    filters = builder.query_hash[:query][:custom_filters_score][:filters]
    expected = {
      filter: { term: { search_format_types: "announcement" } },
      script: "((0.05 / ((3.16*pow(10,-11)) * abs(time() - doc['public_timestamp'].date.getMillis()) + 0.05)) + 0.12)"
    }
    assert_equal expected, filters.last
  end

  def test_can_scope_to_an_organisation
    builder = Elasticsearch::SearchQueryBuilder.new("navajo", "foreign-commonwealth-office")
    term_condition = extract_condition_by_type(builder.query_hash, :term)
    expected = {
      term: { organisations: "foreign-commonwealth-office" }
    }
    assert_equal expected, term_condition
  end

  def test_escapes_the_query_for_lucene
    builder = Elasticsearch::SearchQueryBuilder.new("how?")

    query_string_condition = extract_condition_by_type(builder.query_hash, :query_string)
    assert_equal "how\\?", query_string_condition[:query_string][:query]
  end
end
