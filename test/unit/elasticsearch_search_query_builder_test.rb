require "test_helper"
require "elasticsearch/search_query_builder"

class SearchQueryBuilderTest < ShouldaUnitTestCase

  def mappings(properties = {})
    {
      "edition" => {
        "_all" => { "enabled" => true },
        "properties" => properties
      }
    }
  end

  def extract_condition_by_type(query_hash, condition_type)
    must_conditions = query_hash[:query][:custom_filters_score][:query][:bool][:should][0][:bool][:must]
    must_conditions.find { |condition| condition.keys == [condition_type] }
  end

  def test_query_string_condition
    builder = Elasticsearch::SearchQueryBuilder.new("tomahawk", mappings)

    query_string_condition = extract_condition_by_type(builder.query_hash, :match)
    query_string_condition[:match][:_all].delete(:minimum_should_match)
    expected = {
      match: {
        _all: {
          query: "tomahawk",
          analyzer: "query_default"
        },
      }
    }
    assert_equal expected, query_string_condition
  end

  def test_minimum_should_match_has_sensible_default
    builder = Elasticsearch::SearchQueryBuilder.new("one two three", mappings)

    must_conditions = builder.query_hash[:query][:custom_filters_score][:query][:bool][:should][0][:bool][:must]
    assert_equal "2<2 3<3 7<50%", must_conditions[0][:match][:_all][:minimum_should_match]
  end

  def test_shingle_boosts
    builder = Elasticsearch::SearchQueryBuilder.new("quick brown fox", mappings)
    shingle_condition = builder.query_hash[:query][:custom_filters_score][:query][:bool][:should][0][:bool][:should].detect do |condition|
      condition[:multi_match] &&
          condition[:multi_match][:analyzer] == "shingled_query_analyzer"
    end

    expected = {
      multi_match: {
        query: "quick brown fox",
        operator: "or",
        fields: ["title", "acronym", "description", "indexable_content"],
        analyzer: "shingled_query_analyzer"
      }
    }
    assert_equal expected, shingle_condition
  end

  def test_format_boosts
    builder = Elasticsearch::SearchQueryBuilder.new("cherokee", mappings)
    filters = builder.query_hash[:query][:custom_filters_score][:filters]

    expected = [
      { filter: { term: { format: "smart-answer" } },      boost: 1.5 },
      { filter: { term: { format: "transaction" } },       boost: 1.5 },
      { filter: { term: { format: "topical_event" } },     boost: 1.5 },
      { filter: { term: { format: "minister" } },          boost: 1.7 },
      { filter: { term: { format: "organisation" } },      boost: 2.5 },
      { filter: { term: { format: "topic" } },             boost: 1.5 },
      { filter: { term: { format: "document_series" } },   boost: 1.3 },
      { filter: { term: { format: "document_collection" } }, boost: 1.3 },
      { filter: { term: { format: "operational_field" } }, boost: 1.5 },
    ]
    assert_equal expected, filters[0..-2]
  end

  def test_time_boost
    builder = Elasticsearch::SearchQueryBuilder.new("sioux", mappings)
    filters = builder.query_hash[:query][:custom_filters_score][:filters]
    expected = {
      filter: { term: { search_format_types: "announcement" } },
      script: "((0.05 / ((3.16*pow(10,-11)) * abs(time() - doc['public_timestamp'].date.getMillis()) + 0.05)) + 0.12)"
    }
    assert_equal expected, filters.last
  end

  def test_can_scope_to_an_organisation
    builder = Elasticsearch::SearchQueryBuilder.new("navajo", mappings, organisation: "foreign-commonwealth-office")
    term_condition = extract_condition_by_type(builder.query_hash, :term)
    expected = {
      term: { organisations: "foreign-commonwealth-office" }
    }
    assert_equal expected, term_condition
  end

  def test_specifies_no_sort_if_none_provided
    builder = Elasticsearch::SearchQueryBuilder.new("pie", mappings)
    assert_equal [], builder.query_hash[:sort]
  end

  def test_can_order_by_any_field
    builder = Elasticsearch::SearchQueryBuilder.new("pie", mappings, sort: "public_timestamp", order: "asc")
    expected = [
      { "public_timestamp" => { "order" => "asc" } }
    ]
    assert_equal expected, builder.query_hash[:sort]
  end

  def test_defaults_to_desc_for_sort_order
    builder = Elasticsearch::SearchQueryBuilder.new("pie", mappings, sort: "public_timestamp")
    expected = [
      { "public_timestamp" => { "order" => "desc" } }
    ]
    assert_equal expected, builder.query_hash[:sort]
  end

  def test_escapes_the_query_for_lucene
    builder = Elasticsearch::SearchQueryBuilder.new("how?", mappings)

    query_string_condition = extract_condition_by_type(builder.query_hash, :match)
    assert_equal "how\\?", query_string_condition[:match][:_all][:query]
  end

  def test_can_optionally_specify_limit
    builder = Elasticsearch::SearchQueryBuilder.new("anything", mappings, limit: 123)

    assert_equal 123, builder.query_hash[:size]
  end

  context "validating the query" do
    should "reject ordering by anything but 'asc' or 'desc'" do
      builder = Elasticsearch::SearchQueryBuilder.new("anything", mappings, order: "elephant")

      assert_equal false, builder.valid?
      assert_equal "Unexpected ordering: elephant", builder.error
    end

    should "reject sorting on fields not in the mappings" do
      fields = { "public_timestamp" => { "type" => "date" } }
      builder = Elasticsearch::SearchQueryBuilder.new("anything", mappings(fields), sort: "yo_mama")

      assert_equal false, builder.valid?
      assert_equal "Sorting on unknown property: yo_mama", builder.error
    end
  end
end
