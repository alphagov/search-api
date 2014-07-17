require "test_helper"
require "search_parameter_parser"

class SearchParameterParserTest < ShouldaUnitTestCase

  def expected_params(params)
    {
      start: 0,
      count: 10,
      query: nil,
      order: nil,
      return_fields: BaseParameterParser::DEFAULT_RETURN_FIELDS,
      filters: {},
      facets: {},
      debug: {},
    }.merge(params)
  end

  def expected_facet_params(params)
    {
      requested: 0,
      examples: 0,
      example_fields: BaseParameterParser::DEFAULT_FACET_EXAMPLE_FIELDS,
      example_scope: nil,
    }.merge(params)
  end

  should "return valid params given nothing" do
    p = SearchParameterParser.new({})

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about an unknown parameter" do
    p = SearchParameterParser.new({"p" => ["extra"]})

    assert_equal("Unexpected parameters: p", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about multiple unknown parameters" do
    p = SearchParameterParser.new({"p" => ["extra"], "boo" => ["goose"]})

    assert_equal("Unexpected parameters: p, boo", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "understand the start parameter" do
    p = SearchParameterParser.new({"start" => ["5"]})

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(start: 5), p.parsed_params)
  end

  should "complain about a non-integer start parameter" do
    p = SearchParameterParser.new({"start" => ["5.5"]})

    assert_equal("Invalid value \"5.5\" for parameter \"start\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a negative start parameter" do
    p = SearchParameterParser.new({"start" => ["-1"]})

    assert_equal("Invalid negative value \"-1\" for parameter \"start\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a non-decimal start parameter" do
    p = SearchParameterParser.new({"start" => ["x"]})

    assert_equal("Invalid value \"x\" for parameter \"start\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a repeated start parameter" do
    p = SearchParameterParser.new("start" => ["2", "3"])

    assert_equal(%{Too many values (2) for parameter "start" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(start: 2), p.parsed_params)
  end

  should "understand the count parameter" do
    p = SearchParameterParser.new({"count" => ["5"]})

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(count: 5), p.parsed_params)
  end

  should "complain about a non-integer count parameter" do
    p = SearchParameterParser.new({"count" => ["5.5"]})

    assert_equal("Invalid value \"5.5\" for parameter \"count\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a negative count parameter" do
    p = SearchParameterParser.new({"count" => ["-1"]})

    assert_equal("Invalid negative value \"-1\" for parameter \"count\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a non-decimal count parameter" do
    p = SearchParameterParser.new({"count" => ["x"]})

    assert_equal("Invalid value \"x\" for parameter \"count\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a repeated count parameter" do
    p = SearchParameterParser.new("count" => ["2", "3"])

    assert_equal(%{Too many values (2) for parameter "count" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(count: 2), p.parsed_params)
  end

  should "understand the q parameter" do
    p = SearchParameterParser.new({"q" => ["search-term"]})

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(query: "search-term"), p.parsed_params)
  end

  should "complain about a repeated q parameter" do
    p = SearchParameterParser.new("q" => ["hello", "world"])

    assert_equal(%{Too many values (2) for parameter "q" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(query: "hello"), p.parsed_params)
  end

  should "understand filter paramers" do
    p = SearchParameterParser.new({"filter_organisations" => ["hm-magic"]})

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(filters: {"organisations" => ["hm-magic"]}), p.parsed_params)
  end

  should "understand multiple filter paramers" do
    p = SearchParameterParser.new({"filter_organisations" => ["hm-magic", "hmrc"]})

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(filters: {"organisations" => ["hm-magic", "hmrc"]}), p.parsed_params)
  end

  should "complain about disallowed filter fields" do
    p = SearchParameterParser.new({"filter_spells" => ["levitation"],
                                   "filter_organisations" => ["hm-magic"]})

    assert_equal(%{"spells" is not a valid filter field}, p.error)
    assert !p.valid?
    assert_equal(expected_params({filters: {"organisations" => ["hm-magic"]}}), p.parsed_params)
  end

  should "rewrite document_type filter to _type filter" do
    p = SearchParameterParser.new("filter_document_type" => ["cma_case"])

    assert_equal(
      hash_including(filters: { "_type" => ["cma_case"] }),
      p.parsed_params
    )
  end

  should "understand an ascending sort" do
    p = SearchParameterParser.new("order" => ["public_timestamp"])

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({order: ["public_timestamp", "asc"]}), p.parsed_params)
  end

  should "understand a descending sort" do
    p = SearchParameterParser.new("order" => ["-public_timestamp"])

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({order: ["public_timestamp", "desc"]}), p.parsed_params)
  end

  should "complain about disallowed sort fields" do
    p = SearchParameterParser.new("order" => ["spells"])

    assert_equal(%{"spells" is not a valid sort field}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about disallowed descending sort fields" do
    p = SearchParameterParser.new("order" => ["-spells"])

    assert_equal(%{"spells" is not a valid sort field}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a repeated sort parameter" do
    p = SearchParameterParser.new("order" => ["public_timestamp", "something_else"])

    assert_equal(%{Too many values (2) for parameter "order" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(order: ["public_timestamp", "asc"]), p.parsed_params)
  end
 
  should "understand a facet field" do
    p = SearchParameterParser.new("facet_organisations" => ["10"])

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({facets: {
      "organisations" => expected_facet_params({requested: 10})
    }}), p.parsed_params)
  end

  should "understand multiple facet fields" do
    p = SearchParameterParser.new(
      "facet_organisations" => ["10"],
      "facet_section" => ["5"],
    )

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({facets: {
      "organisations" => expected_facet_params({requested: 10}),
      "section" => expected_facet_params({requested: 5})
    }}), p.parsed_params)
  end

  should "complain about disallowed facet fields" do
    p = SearchParameterParser.new("facet_spells" => ["10"],
                                  "facet_organisations" => ["10"])

    assert_equal(%{"spells" is not a valid facet field}, p.error)
    assert !p.valid?
    assert_equal(expected_params({facets: {
      "organisations" => expected_facet_params({requested: 10})
    }}), p.parsed_params)
  end

  should "complain about invalid values for facet parameter" do
    p = SearchParameterParser.new("facet_spells" => ["levitation"],
                                  "facet_organisations" => ["magic"])

    assert_equal(%{"spells" is not a valid facet field. Invalid value "magic" for first parameter for facet "organisations" (expected positive integer)}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about empty values for facet parameter" do
    p = SearchParameterParser.new("facet_organisations" => [""])

    assert_equal(%{Invalid value "" for first parameter for facet "organisations" (expected positive integer)}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a repeated facet parameter" do
    p = SearchParameterParser.new("facet_organisations" => ["5", "6"])

    assert_equal(%{Too many values (2) for parameter "facet_organisations" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(facets: {
      "organisations" => expected_facet_params(requested: 5)
    }), p.parsed_params)
  end
 
  should "allow options in the values for the facet parameter" do
    p = SearchParameterParser.new("facet_organisations" => ["10,examples:5,example_fields:slug:title,example_scope:global"])

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({
      facets: {
        "organisations" => expected_facet_params({
          requested: 10,
          examples: 5,
          example_fields: ["slug", "title"],
          example_scope: :global,
      })}}), p.parsed_params)
  end

  should "complain about a repeated examples option" do
    p = SearchParameterParser.new("facet_organisations" => ["10,examples:5,examples:6,example_scope:global"])

    assert_equal(%{Too many values (2) for parameter "examples" in facet "organisations" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "merge fields from repeated example_fields options" do
    p = SearchParameterParser.new("facet_organisations" => ["10,examples:5,example_fields:slug,example_fields:title:link,example_scope:global"])

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({
      facets: {
        "organisations" => expected_facet_params({
          requested: 10,
          examples: 5,
          example_fields: ["slug", "title", "link"],
          example_scope: :global,
      })}}), p.parsed_params)
  end

  should "require the example_scope to be set to global" do
    # Global scope is the only supported scope at present, but it's likely to
    # be a surprising default, so we require that callers explicitly specify
    # it.
    p = SearchParameterParser.new("facet_organisations" => ["10,examples:5,example_fields:slug:title"])

    assert_equal("example_scope parameter must currently be set to global when requesting examples", p.error)
    assert !p.valid?
    assert_equal(expected_params({facets: {}}), p.parsed_params)
  end

  should "complain about a repeated example_scope option" do
    p = SearchParameterParser.new("facet_organisations" => ["10,examples:5,example_scope:global,example_scope:global"])

    assert_equal(%{Too many values (2) for parameter "example_scope" in facet "organisations" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "validate options in the values for the facet parameter" do
    p = SearchParameterParser.new("facet_organisations" => ["10,example:5,examples:lots,example_fields:unknown:title"])

    assert_equal([
      %{Invalid value "lots" for parameter "examples" in facet "organisations" (expected positive integer)},
      %{Some requested fields are not valid return fields: ["unknown"] in parameter "example_fields" in facet "organisations"},
      %{Unexpected options in facet "organisations": example},
    ].join(". "), p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "understand the fields parameter" do
    p = SearchParameterParser.new("fields" => ["title", "description"])

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({return_fields: ["title", "description"]}), p.parsed_params)
  end

  should "complain about invalid fields parameters" do
    p = SearchParameterParser.new("fields" => ["title", "waffle"])

    assert_equal("Some requested fields are not valid return fields: [\"waffle\"]", p.error)
    assert !p.valid?
    assert_equal(expected_params({return_fields: ["title"]}), p.parsed_params)
  end

  should "understand the debug parameter" do
    p = SearchParameterParser.new("debug" => ["disable_best_bets,disable_popularity,,unknown_option"])

    assert_equal(%{Unknown debug option "unknown_option"}, p.error)
    assert !p.valid?
    assert_equal expected_params({debug: {disable_best_bets: true, disable_popularity: true}}), p.parsed_params
  end

  should "merge values from repeated debug parameters" do
    p = SearchParameterParser.new("debug" => ["disable_best_bets,explain", "disable_popularity"])

    assert_equal("", p.error)
    assert p.valid?
    assert_equal expected_params({debug: {disable_best_bets: true, explain: true, disable_popularity: true}}), p.parsed_params
  end

  should "ignore empty options in the debug parameter" do
    p = SearchParameterParser.new("debug" => [",,"])

    assert_equal("", p.error)
    assert p.valid?
    assert_equal expected_params({debug: {}}), p.parsed_params
  end

  should "understand explain in the debug parameter" do
    p = SearchParameterParser.new("debug" => ["explain"])

    assert p.valid?
    assert_equal expected_params({debug: {explain: true}}), p.parsed_params
  end

  should "understand disable_synonyms in the debug parameter" do
    p = SearchParameterParser.new("debug" => ["disable_synonyms"])

    assert p.valid?
    assert_equal expected_params({debug: {disable_synonyms: true}}), p.parsed_params
  end
end
