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
      filters: [],
      facets: {},
      debug: {},
    }.merge(params)
  end

  def expected_facet_params(params)
    {
      requested: 0,
      scope: :exclude_field_filter,
      order: BaseParameterParser::DEFAULT_FACET_SORT,
      examples: 0,
      example_fields: BaseParameterParser::DEFAULT_FACET_EXAMPLE_FIELDS,
      example_scope: nil,
    }.merge(params)
  end

  def text_filter(field_name, values, rejects=false)
    SearchParameterParser::TextFieldFilter.new(field_name, values, rejects)
  end

  def setup
    @schema = stub("combined index schema")
    date_type = stub("date type")
    date_type.stubs(:filter_type).returns("date")
    identifier_type = stub("identifier type")
    identifier_type.stubs(:filter_type).returns("text")
    string_type = stub("string type")
    string_type.stubs(:filter_type).returns(nil)
    field_definitions = {}
    allowed_filter_fields = []
    [
      ["title", string_type],
      ["description", string_type],
      ["mainstream_browse_pages", identifier_type],
      ["organisations", identifier_type],
      ["public_timestamp", date_type],
      ["slug", identifier_type],
      ["link", identifier_type],

      ["case_type", identifier_type],
      ["opened_date", date_type],
    ].each { |field, type|
      definition = stub("#{field} definition")
      definition.stubs(:type).returns(type)
      field_definitions[field] = definition
      if type.filter_type
        allowed_filter_fields << field
      end
    }
    @schema.stubs(:field_definitions).returns(field_definitions)
    @schema.stubs(:allowed_filter_fields).returns(allowed_filter_fields)
  end

  should "return valid params given nothing" do
    p = SearchParameterParser.new({}, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about an unknown parameter" do
    p = SearchParameterParser.new({"p" => ["extra"]}, @schema)

    assert_equal("Unexpected parameters: p", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about multiple unknown parameters" do
    p = SearchParameterParser.new({"p" => ["extra"], "boo" => ["goose"]}, @schema)

    assert_equal("Unexpected parameters: p, boo", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "understand the start parameter" do
    p = SearchParameterParser.new({"start" => ["5"]}, @schema) 
    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(start: 5), p.parsed_params)
  end

  should "complain about a non-integer start parameter" do
    p = SearchParameterParser.new({"start" => ["5.5"]}, @schema)

    assert_equal("Invalid value \"5.5\" for parameter \"start\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a negative start parameter" do
    p = SearchParameterParser.new({"start" => ["-1"]}, @schema)

    assert_equal("Invalid negative value \"-1\" for parameter \"start\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a non-decimal start parameter" do
    p = SearchParameterParser.new({"start" => ["x"]}, @schema)

    assert_equal("Invalid value \"x\" for parameter \"start\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a repeated start parameter" do
    p = SearchParameterParser.new({"start" => ["2", "3"]}, @schema)

    assert_equal(%{Too many values (2) for parameter "start" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(start: 2), p.parsed_params)
  end

  should "understand the count parameter" do
    p = SearchParameterParser.new({"count" => ["5"]}, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(count: 5), p.parsed_params)
  end

  should "complain about a non-integer count parameter" do
    p = SearchParameterParser.new({"count" => ["5.5"]}, @schema)

    assert_equal("Invalid value \"5.5\" for parameter \"count\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a negative count parameter" do
    p = SearchParameterParser.new({"count" => ["-1"]}, @schema)

    assert_equal("Invalid negative value \"-1\" for parameter \"count\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a non-decimal count parameter" do
    p = SearchParameterParser.new({"count" => ["x"]}, @schema)

    assert_equal("Invalid value \"x\" for parameter \"count\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a repeated count parameter" do
    p = SearchParameterParser.new({"count" => ["2", "3"]}, @schema)

    assert_equal(%{Too many values (2) for parameter "count" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(count: 2), p.parsed_params)
  end

  should "understand the q parameter" do
    p = SearchParameterParser.new({"q" => ["search-term"]}, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(query: "search-term"), p.parsed_params)
  end

  should "complain about a repeated q parameter" do
    p = SearchParameterParser.new({"q" => ["hello", "world"]}, @schema)

    assert_equal(%{Too many values (2) for parameter "q" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(query: "hello"), p.parsed_params)
  end

  should "strip whitespace from the query" do
    p = SearchParameterParser.new({"q" => ["cheese "]}, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(query: "cheese"), p.parsed_params)
  end

  should "put the query in normalized form" do
    p = SearchParameterParser.new({"q" => ["cafe\u0300 "]}, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(query: "caf\u00e8"), p.parsed_params)
  end

  should "complain about invalid unicode in the query" do
    p = SearchParameterParser.new({"q" => ["\xff"]}, @schema)

    assert_equal("Invalid unicode in query", p.error)
    assert !p.valid?
    assert_equal(expected_params(query: nil), p.parsed_params)
  end

  should "understand filter paramers" do
    p = SearchParameterParser.new({"filter_organisations" => ["hm-magic"]}, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(
      hash_including(filters: [
        text_filter("organisations", ["hm-magic"])
      ]),
      p.parsed_params,
    )
  end

  should "understand reject paramers" do
    p = SearchParameterParser.new({"reject_organisations" => ["hm-magic"]}, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(
      hash_including(filters: [
        text_filter("organisations", ["hm-magic"], true)
      ]),
      p.parsed_params,
    )
  end

  should "understand some rejects and some filter paramers" do
    p = SearchParameterParser.new({
      "reject_organisations" => ["hm-magic"],
      "filter_mainstream_browse_pages" => ["cheese"],
    }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(
      hash_including(filters: [
        text_filter("mainstream_browse_pages", ["cheese"]),
        text_filter("organisations", ["hm-magic"], true),
      ]),
      p.parsed_params,
    )
  end

  should "understand multiple filter paramers" do
    p = SearchParameterParser.new({"filter_organisations" => ["hm-magic", "hmrc"]}, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(
      expected_params(
        filters: [
          text_filter("organisations", [
              "hm-magic",
              "hmrc",
            ]
          )
        ],
      ),
      p.parsed_params,
    )
  end

  should "understand filter for missing field" do
    p = SearchParameterParser.new({"filter_organisations" => ["_MISSING"]}, @schema)

    assert_equal("", p.error)
    assert p.valid?

    filters = p.parsed_params[:filters]
    assert_equal 1, filters.size
    assert_equal "organisations", filters[0].field_name
    assert_equal true, filters[0].include_missing
    assert_equal [], filters[0].values
  end

  should "understand filter for missing field or specific value" do
    p = SearchParameterParser.new({"filter_organisations" => ["_MISSING", "hmrc"]}, @schema)

    assert_equal("", p.error)
    assert p.valid?

    filters = p.parsed_params[:filters]
    assert_equal 1, filters.size
    assert_equal "organisations", filters[0].field_name
    assert_equal true, filters[0].include_missing
    assert_equal ["hmrc"], filters[0].values
  end

  should "complain about disallowed filter fields" do
    p = SearchParameterParser.new(
      {
        "filter_spells" => ["levitation"],
        "filter_organisations" => ["hm-magic"]
      },
      @schema,
    )

    assert_equal(%{"spells" is not a valid filter field}, p.error)
    assert !p.valid?
    assert_equal(
      expected_params(filters: [text_filter("organisations", ["hm-magic"])]),
      p.parsed_params,
    )
  end

  should "complain about disallowed reject fields" do
    p = SearchParameterParser.new(
      {
        "reject_spells" => ["levitation"],
        "reject_organisations" => ["hm-magic"]
      },
      @schema,
    )

    assert_equal(%{"spells" is not a valid reject field}, p.error)
    assert !p.valid?
    assert_equal(
      expected_params(filters: [text_filter("organisations", ["hm-magic"], true)]),
      p.parsed_params,
    )
  end

  should "rewrite document_type filter to _type filter" do
    parser = SearchParameterParser.new(
      { "filter_document_type" => ["cma_case"] },
      @schema,
    )

    assert_equal(
      hash_including(filters: [ text_filter("_type", ["cma_case"]) ]),
      parser.parsed_params,
    )
  end

  context "when the filter field is a date type" do
    should "include the type in return value of #parsed_params" do
      params = {
        "filter_document_type" => ["cma_case"],
        "filter_opened_date" => "from:2014-04-01 00:00,to:2014-04-02 00:00",
      }

      parser = SearchParameterParser.new(params, @schema)

      assert parser.valid?, "Parameters should be valid: #{parser.errors}"

      opened_date_filter = parser.parsed_params.fetch(:filters)
      .find { |filter| filter.field_name == "opened_date" }

      assert_equal(
        Date.parse("2014-04-01 00:00"),
        opened_date_filter.values.first.from,
      )

      assert_equal(
        Date.parse("2014-04-02 00:00"),
        opened_date_filter.values.first.to,
      )
    end

    should "understand date filter for missing field or specific value" do
      parser = SearchParameterParser.new({
        "filter_document_type" => ["cma_case"],
        "filter_opened_date" => ["_MISSING", "from:2014-04-01 00:00,to:2014-04-02 00:00"],
      }, @schema)

      assert_equal("", parser.error)
      assert parser.valid?

      opened_date_filter = parser.parsed_params.fetch(:filters)
      .find { |filter| filter.field_name == "opened_date" }

      assert_equal "opened_date", opened_date_filter.field_name
      assert_equal true, opened_date_filter.include_missing

      assert_equal(
        Date.parse("2014-04-01 00:00"),
        opened_date_filter.values.first.from,
      )

      assert_equal(
        Date.parse("2014-04-02 00:00"),
        opened_date_filter.values.first.to,
      )
    end
  end

  context "filtering a date field with an invalid date" do
    should "does not filter on date" do
      params = {
        "filter_document_type" => ["cma_case"],
        "filter_opened_date" => "from:2014-bananas-01 00:00,to:2014-04-02 00:00",
      }

      parser = SearchParameterParser.new(params, @schema)

      opened_date_filter = parser.parsed_params.fetch(:filters)
      .find { |filter| filter.field_name == "opened_date" }
    end
  end

  should "understand an ascending sort" do
    p = SearchParameterParser.new({"order" => ["public_timestamp"]}, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({order: ["public_timestamp", "asc"]}), p.parsed_params)
  end

  should "understand a descending sort" do
    p = SearchParameterParser.new({"order" => ["-public_timestamp"]}, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({order: ["public_timestamp", "desc"]}), p.parsed_params)
  end

  should "complain about disallowed sort fields" do
    p = SearchParameterParser.new({"order" => ["spells"]}, @schema)

    assert_equal(%{"spells" is not a valid sort field}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about disallowed descending sort fields" do
    p = SearchParameterParser.new({"order" => ["-spells"]}, @schema)

    assert_equal(%{"spells" is not a valid sort field}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a repeated sort parameter" do
    p = SearchParameterParser.new({"order" => ["public_timestamp", "something_else"]}, @schema)

    assert_equal(%{Too many values (2) for parameter "order" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(order: ["public_timestamp", "asc"]), p.parsed_params)
  end

  should "understand a facet field" do
    p = SearchParameterParser.new({"facet_organisations" => ["10"]}, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({facets: {
      "organisations" => expected_facet_params({requested: 10})
    }}), p.parsed_params)
  end

  should "understand multiple facet fields" do
    p = SearchParameterParser.new({
      "facet_organisations" => ["10"],
      "facet_section" => ["5"],
    }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({facets: {
      "organisations" => expected_facet_params({requested: 10}),
      "section" => expected_facet_params({requested: 5})
    }}), p.parsed_params)
  end

  should "complain about disallowed facet fields" do
    p = SearchParameterParser.new({
      "facet_spells" => ["10"],
      "facet_organisations" => ["10"],
    }, @schema)

    assert_equal(%{"spells" is not a valid facet field}, p.error)
    assert !p.valid?
    assert_equal(expected_params({facets: {
      "organisations" => expected_facet_params({requested: 10})
    }}), p.parsed_params)
  end

  should "complain about invalid values for facet parameter" do
    p = SearchParameterParser.new({
      "facet_spells" => ["levitation"],
      "facet_organisations" => ["magic"],
    }, @schema)

    assert_equal(%{"spells" is not a valid facet field. Invalid value "magic" for first parameter for facet "organisations" (expected positive integer)}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about empty values for facet parameter" do
    p = SearchParameterParser.new({"facet_organisations" => [""]}, @schema)

    assert_equal(%{Invalid value "" for first parameter for facet "organisations" (expected positive integer)}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a repeated facet parameter" do
    p = SearchParameterParser.new({"facet_organisations" => ["5", "6"]}, @schema)

    assert_equal(%{Too many values (2) for parameter "facet_organisations" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(facets: {
      "organisations" => expected_facet_params(requested: 5)
    }), p.parsed_params)
  end

  should "allow options in the values for the facet parameter" do
    p = SearchParameterParser.new({
      "facet_organisations" => ["10,examples:5,example_fields:slug:title,example_scope:global"],
    }, @schema)

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

  should "understand the order option in facet parameters" do
    p = SearchParameterParser.new({
      "facet_organisations" => ["10,order:filtered:value.link:-count"],
    }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({
      facets: {
        "organisations" => expected_facet_params({
          requested: 10,
          order: [[:filtered, 1], [:"value.link", 1], [:count, -1]],
      })}}), p.parsed_params)
  end

  should "complain about invalid order options in facet parameters" do
    p = SearchParameterParser.new({
      "facet_organisations" => ["10,order:filt:value.unknown"],
    }, @schema)

    assert_equal(%{"filt" is not a valid sort option in facet "organisations". "value.unknown" is not a valid sort option in facet "organisations"}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end


  should "handle repeated order options in facet parameters" do
    p = SearchParameterParser.new({
      "facet_organisations" => ["10,order:filtered,order:value.link:-count"],
    }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({
      facets: {
        "organisations" => expected_facet_params({
          requested: 10,
          order: [[:filtered, 1], [:"value.link", 1], [:count, -1]],
      })}}), p.parsed_params)
  end

  should "understand the scope option in facet parameters" do
    p = SearchParameterParser.new({
      "facet_organisations" => ["10,scope:all_filters"],
    }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({
      facets: {
        "organisations" => expected_facet_params({
          requested: 10,
          scope: :all_filters,
        })
      }
    }), p.parsed_params)
  end

  should "complain about invalid scope options in facet parameters" do
    p = SearchParameterParser.new({
      "facet_organisations" => ["10,scope:unknown"],
    }, @schema)

    assert_equal(%{"unknown" is not a valid scope option in facet "organisations"}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a repeated examples option" do
    p = SearchParameterParser.new({
      "facet_organisations" => ["10,examples:5,examples:6,example_scope:global"],
    }, @schema)

    assert_equal(%{Too many values (2) for parameter "examples" in facet "organisations" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "merge fields from repeated example_fields options" do
    p = SearchParameterParser.new({
      "facet_organisations" => ["10,examples:5,example_fields:slug,example_fields:title:link,example_scope:global"],
    }, @schema)

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

  should "require the example_scope to be set" do
    p = SearchParameterParser.new({
      "facet_organisations" => ["10,examples:5,example_fields:slug:title"],
    }, @schema)

    assert_equal("example_scope parameter must be set to 'query' or 'global' when requesting examples", p.error)
    assert !p.valid?
    assert_equal(expected_params({facets: {}}), p.parsed_params)
  end

  should "allow example_scope to be set to 'query'" do
    p = SearchParameterParser.new({
      "facet_organisations" => ["10,examples:5,example_fields:slug:title,example_scope:query"],
    }, @schema)

    assert p.valid?
    assert_equal(expected_params({
      facets: {
        "organisations" => expected_facet_params({
          requested: 10,
          examples: 5,
          example_fields: ["slug", "title"],
          example_scope: :query,
        })
      }
    }), p.parsed_params)
  end

  should "complain about an invalid example_scope option" do
    p = SearchParameterParser.new({
      "facet_organisations" => ["10,examples:5,example_scope:invalid"],
    }, @schema)

    assert_equal("example_scope parameter must be set to 'query' or 'global' when requesting examples", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "complain about a repeated example_scope option" do
    p = SearchParameterParser.new({
      "facet_organisations" => ["10,examples:5,example_scope:global,example_scope:global"],
    }, @schema)

    assert_equal(%{Too many values (2) for parameter "example_scope" in facet "organisations" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "validate options in the values for the facet parameter" do
    p = SearchParameterParser.new({
      "facet_organisations" => ["10,example:5,examples:lots,example_fields:unknown:title"],
    }, @schema)

    assert_equal([
      %{Invalid value "lots" for parameter "examples" in facet "organisations" (expected positive integer)},
      %{Some requested fields are not valid return fields: ["unknown"] in parameter "example_fields" in facet "organisations"},
      %{Unexpected options in facet "organisations": example},
    ].join(". "), p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  should "understand the fields parameter" do
    p = SearchParameterParser.new({"fields" => ["title", "description"]}, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({return_fields: ["title", "description"]}), p.parsed_params)
  end

  should "complain about invalid fields parameters" do
    p = SearchParameterParser.new({"fields" => ["title", "waffle"]}, @schema)

    assert_equal("Some requested fields are not valid return fields: [\"waffle\"]", p.error)
    assert !p.valid?
    assert_equal(expected_params({return_fields: ["title"]}), p.parsed_params)
  end

  should "understand the debug parameter" do
    p = SearchParameterParser.new({"debug" => ["disable_best_bets,disable_popularity,,unknown_option"]}, @schema)

    assert_equal(%{Unknown debug option "unknown_option"}, p.error)
    assert !p.valid?
    assert_equal expected_params({debug: {disable_best_bets: true, disable_popularity: true}}), p.parsed_params
  end

  should "merge values from repeated debug parameters" do
    p = SearchParameterParser.new({"debug" => ["disable_best_bets,explain", "disable_popularity"]}, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal expected_params({debug: {disable_best_bets: true, explain: true, disable_popularity: true}}), p.parsed_params
  end

  should "ignore empty options in the debug parameter" do
    p = SearchParameterParser.new({"debug" => [",,"]}, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal expected_params({debug: {}}), p.parsed_params
  end

  should "understand explain in the debug parameter" do
    p = SearchParameterParser.new({"debug" => ["explain"]}, @schema)

    assert p.valid?
    assert_equal expected_params({debug: {explain: true}}), p.parsed_params
  end

  should "understand disable_synonyms in the debug parameter" do
    p = SearchParameterParser.new({"debug" => ["disable_synonyms"]}, @schema)

    assert p.valid?
    assert_equal expected_params({debug: {disable_synonyms: true}}), p.parsed_params
  end
end
