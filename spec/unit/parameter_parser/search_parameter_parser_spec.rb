require 'spec_helper'

RSpec.describe 'SearchParameterParserTest', tags: ['shoulda'] do
  def expected_params(params)
    {
      start: 0,
      count: 10,
      query: nil,
      similar_to: nil,
      order: nil,
      return_fields: BaseParameterParser::DEFAULT_RETURN_FIELDS,
      filters: [],
      aggregates: {},
      aggregate_name: :aggregates,
      debug: {},
      suggest: [],
      ab_tests: {},
    }.merge(params)
  end

  def expected_aggregate_params(params)
    {
      requested: 0,
      scope: :exclude_field_filter,
      order: BaseParameterParser::DEFAULT_AGGREGATE_SORT,
      examples: 0,
      example_fields: BaseParameterParser::DEFAULT_AGGREGATE_EXAMPLE_FIELDS,
      example_scope: nil,
    }.merge(params)
  end

  def text_filter(field_name, values, rejects = false)
    SearchParameterParser::TextFieldFilter.new(field_name, values, rejects)
  end

  before do
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

  it "return valid params given nothing" do
    p = SearchParameterParser.new({}, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "complain about an unknown parameter" do
    p = SearchParameterParser.new({ "p" => ["extra"] }, @schema)

    assert_equal("Unexpected parameters: p", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "allow the c parameter to be anything" do
    p = SearchParameterParser.new({ "c" => ["1234567890"] }, @schema)

    assert p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "complain about multiple unknown parameters" do
    p = SearchParameterParser.new({ "p" => ["extra"], "boo" => ["goose"] }, @schema)

    assert_equal("Unexpected parameters: p, boo", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "understand the start parameter" do
    p = SearchParameterParser.new({ "start" => ["5"] }, @schema)
    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(start: 5), p.parsed_params)
  end

  it "complain about a non-integer start parameter" do
    p = SearchParameterParser.new({ "start" => ["5.5"] }, @schema)

    assert_equal("Invalid value \"5.5\" for parameter \"start\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "complain about a negative start parameter" do
    p = SearchParameterParser.new({ "start" => ["-1"] }, @schema)

    assert_equal("Invalid negative value \"-1\" for parameter \"start\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "complain about a non-decimal start parameter" do
    p = SearchParameterParser.new({ "start" => ["x"] }, @schema)

    assert_equal("Invalid value \"x\" for parameter \"start\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "complain about a repeated start parameter" do
    p = SearchParameterParser.new({ "start" => %w(2 3) }, @schema)

    assert_equal(%{Too many values (2) for parameter "start" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(start: 2), p.parsed_params)
  end

  it "understand the count parameter" do
    p = SearchParameterParser.new({ "count" => ["5"] }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(count: 5), p.parsed_params)
  end

  it "complain about a non-integer count parameter" do
    p = SearchParameterParser.new({ "count" => ["5.5"] }, @schema)

    assert_equal("Invalid value \"5.5\" for parameter \"count\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "complain about a negative count parameter" do
    p = SearchParameterParser.new({ "count" => ["-1"] }, @schema)

    assert_equal("Invalid negative value \"-1\" for parameter \"count\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "complain about a non-decimal count parameter" do
    p = SearchParameterParser.new({ "count" => ["x"] }, @schema)

    assert_equal("Invalid value \"x\" for parameter \"count\" (expected positive integer)", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "complain about a repeated count parameter" do
    p = SearchParameterParser.new({ "count" => %w(2 3) }, @schema)

    assert_equal(%{Too many values (2) for parameter "count" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(count: 2), p.parsed_params)
  end

  it "complain about an overly large count parameter" do
    p = SearchParameterParser.new({ "count" => %w(1001) }, @schema)

    assert_equal(%{Maximum result set size (as specified in 'count') is 1000}, p.error)
    refute p.valid?
    assert_equal(expected_params(count: 10), p.parsed_params)
  end

  it "understand the q parameter" do
    p = SearchParameterParser.new({ "q" => ["search-term"] }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(query: "search-term"), p.parsed_params)
  end

  it "complain about a repeated q parameter" do
    p = SearchParameterParser.new({ "q" => %w(hello world) }, @schema)

    assert_equal(%{Too many values (2) for parameter "q" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(query: "hello"), p.parsed_params)
  end

  it "strip whitespace from the query" do
    p = SearchParameterParser.new({ "q" => ["cheese "] }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(query: "cheese"), p.parsed_params)
  end

  it "put the query in normalized form" do
    p = SearchParameterParser.new({ "q" => ["cafe\u0300 "] }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(query: "caf\u00e8"), p.parsed_params)
  end

  it "complain about invalid unicode in the query" do
    p = SearchParameterParser.new({ "q" => ["\xff"] }, @schema)

    assert_equal("Invalid unicode in query", p.error)
    assert !p.valid?
    assert_equal(expected_params(query: nil), p.parsed_params)
  end

  it "understand the similar_to parameter" do
    p = SearchParameterParser.new({ "similar_to" => ["/search-term"] }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(similar_to: "/search-term"), p.parsed_params)
  end

  it "complain about a repeated similar_to parameter" do
    p = SearchParameterParser.new({ "similar_to" => %w(/hello /world) }, @schema)

    assert_equal(%{Too many values (2) for parameter "similar_to" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(similar_to: "/hello"), p.parsed_params)
  end

  it "strip whitespace from similar_to parameter" do
    p = SearchParameterParser.new({ "similar_to" => ["/cheese "] }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(similar_to: "/cheese"), p.parsed_params)
  end

  it "put the similar_to parameter in normalized form" do
    p = SearchParameterParser.new({ "similar_to" => ["/cafe\u0300 "] }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(similar_to: "/caf\u00e8"), p.parsed_params)
  end

  it "complain about invalid unicode in the similar_to parameter" do
    p = SearchParameterParser.new({ "similar_to" => ["\xff"] }, @schema)

    assert_equal("Invalid unicode in similar_to", p.error)
    assert !p.valid?
    assert_equal(expected_params(similar_to: nil), p.parsed_params)
  end

  it "complain when both q and similar_to parameters are provided" do
    p = SearchParameterParser.new({ "q" => ["hello"], "similar_to" => ["/world"] }, @schema)

    assert_equal("Parameters 'q' and 'similar_to' cannot be used together", p.error)
    assert !p.valid?
    assert_equal(expected_params(query: "hello", similar_to: "/world"), p.parsed_params)
  end

  it "set the order parameter to nil when the similar_to parameter is provided" do
    p = SearchParameterParser.new({ "similar_to" => ["/hello"], "order" => ["title"] }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params(similar_to: "/hello"), p.parsed_params)
  end

  it "understand filter paramers" do
    p = SearchParameterParser.new({ "filter_organisations" => ["hm-magic"] }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(
      hash_including(filters: [
        text_filter("organisations", ["hm-magic"])
      ]),
      p.parsed_params,
    )
  end

  it "understand reject paramers" do
    p = SearchParameterParser.new({ "reject_organisations" => ["hm-magic"] }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(
      hash_including(filters: [
        text_filter("organisations", ["hm-magic"], true)
      ]),
      p.parsed_params,
    )
  end

  it "understand some rejects and some filter paramers" do
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

  it "understand multiple filter paramers" do
    p = SearchParameterParser.new({ "filter_organisations" => ["hm-magic", "hmrc"] }, @schema)

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

  it "understand filter for missing field" do
    p = SearchParameterParser.new({ "filter_organisations" => ["_MISSING"] }, @schema)

    assert_equal("", p.error)
    assert p.valid?

    filters = p.parsed_params[:filters]
    assert_equal 1, filters.size
    assert_equal "organisations", filters[0].field_name
    assert_equal true, filters[0].include_missing
    assert_equal [], filters[0].values
  end

  it "understand filter for missing field or specific value" do
    p = SearchParameterParser.new({ "filter_organisations" => %w(_MISSING hmrc) }, @schema)

    assert_equal("", p.error)
    assert p.valid?

    filters = p.parsed_params[:filters]
    assert_equal 1, filters.size
    assert_equal "organisations", filters[0].field_name
    assert_equal true, filters[0].include_missing
    assert_equal ["hmrc"], filters[0].values
  end

  it "complain about disallowed filter fields" do
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

  it "complain about disallowed reject fields" do
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

  # TODO: this is deprecated behaviour
  it "rewrite document_type filter to _type filter" do
    parser = SearchParameterParser.new(
      { "filter_document_type" => ["cma_case"] },
      @schema,
    )

    assert_equal(
      hash_including(filters: [text_filter("_type", ["cma_case"])]),
      parser.parsed_params,
    )
  end

  context "when the filter field is a date type" do
    it "include the type in return value of #parsed_params" do
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

    it "understand date filter for missing field or specific value" do
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
    it "does not filter on date" do
      params = {
        "filter_document_type" => ["cma_case"],
        "filter_opened_date" => "from:2014-bananas-01 00:00,to:2014-04-02 00:00",
      }

      parser = SearchParameterParser.new(params, @schema)

      opened_date_filter = parser.parsed_params.fetch(:filters)
        .find { |filter| filter.field_name == "opened_date" }

      assert_nil opened_date_filter
    end
  end

  it "understand an ascending sort" do
    p = SearchParameterParser.new({ "order" => ["public_timestamp"] }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({ order: %w(public_timestamp asc) }), p.parsed_params)
  end

  it "understand a descending sort" do
    p = SearchParameterParser.new({ "order" => ["-public_timestamp"] }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({ order: %w(public_timestamp desc) }), p.parsed_params)
  end

  it "complain about disallowed sort fields" do
    p = SearchParameterParser.new({ "order" => ["spells"] }, @schema)

    assert_equal(%{"spells" is not a valid sort field}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "complain about disallowed descending sort fields" do
    p = SearchParameterParser.new({ "order" => ["-spells"] }, @schema)

    assert_equal(%{"spells" is not a valid sort field}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "complain about a repeated sort parameter" do
    p = SearchParameterParser.new({ "order" => %w(public_timestamp something_else) }, @schema)

    assert_equal(%{Too many values (2) for parameter "order" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(order: %w(public_timestamp asc)), p.parsed_params)
  end

  it "understand a aggregate field" do
    p = SearchParameterParser.new({ "aggregate_organisations" => ["10"] }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({ aggregates: {
      "organisations" => expected_aggregate_params({ requested: 10 })
    } }), p.parsed_params)
  end

  it "understand multiple aggregate fields" do
    p = SearchParameterParser.new({
      "aggregate_organisations" => ["10"],
      "aggregate_mainstream_browse_pages" => ["5"],
    }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({ aggregates: {
      "organisations" => expected_aggregate_params({ requested: 10 }),
      "mainstream_browse_pages" => expected_aggregate_params({ requested: 5 })
    } }), p.parsed_params)
  end

  it "complain about disallowed aggregates fields" do
    p = SearchParameterParser.new({
      "aggregate_spells" => ["10"],
      "aggregate_organisations" => ["10"],
    }, @schema)

    assert_equal(%{"spells" is not a valid aggregate field}, p.error)
    assert !p.valid?
    assert_equal(expected_params({ aggregates: {
      "organisations" => expected_aggregate_params({ requested: 10 })
    } }), p.parsed_params)
  end

  it "complain about invalid values for aggregate parameter" do
    p = SearchParameterParser.new({
      "aggregate_spells" => ["levitation"],
      "aggregate_organisations" => ["magic"],
    }, @schema)

    assert_equal(%{"spells" is not a valid aggregate field. Invalid value "magic" for first parameter for aggregate "organisations" (expected positive integer)}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "complain about empty values for aggregate parameter" do
    p = SearchParameterParser.new({ "aggregate_organisations" => [""] }, @schema)

    assert_equal(%{Invalid value "" for first parameter for aggregate "organisations" (expected positive integer)}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "complain about a repeated aggregate parameter" do
    p = SearchParameterParser.new({ "aggregate_organisations" => %w(5 6) }, @schema)

    assert_equal(%{Too many values (2) for parameter "aggregate_organisations" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params(aggregates: {
      "organisations" => expected_aggregate_params(requested: 5)
    }), p.parsed_params)
  end

  it "allow options in the values for the aggregate parameter" do
    p = SearchParameterParser.new({
      "aggregate_organisations" => ["10,examples:5,example_fields:slug:title,example_scope:global"],
    }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({
      aggregates: {
        "organisations" => expected_aggregate_params({
          requested: 10,
          examples: 5,
          example_fields: %w(slug title),
          example_scope: :global,
      }) } }), p.parsed_params)
  end

  it "understand the order option in aggregate parameters" do
    p = SearchParameterParser.new({
      "aggregate_organisations" => ["10,order:filtered:value.link:-count"],
    }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({
      aggregates: {
        "organisations" => expected_aggregate_params({
          requested: 10,
          order: [[:filtered, 1], [:"value.link", 1], [:count, -1]],
      }) } }), p.parsed_params)
  end

  it "complain about invalid order options in aggregate parameters" do
    p = SearchParameterParser.new({
      "aggregate_organisations" => ["10,order:filt:value.unknown"],
    }, @schema)

    assert_equal(%{"filt" is not a valid sort option in aggregate "organisations". "value.unknown" is not a valid sort option in aggregate "organisations"}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end


  it "handle repeated order options in aggregate parameters" do
    p = SearchParameterParser.new({
      "aggregate_organisations" => ["10,order:filtered,order:value.link:-count"],
    }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({
      aggregates: {
        "organisations" => expected_aggregate_params({
          requested: 10,
          order: [[:filtered, 1], [:"value.link", 1], [:count, -1]],
      }) } }), p.parsed_params)
  end

  it "understand the scope option in aggregate parameters" do
    p = SearchParameterParser.new({
      "aggregate_organisations" => ["10,scope:all_filters"],
    }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({
      aggregates: {
        "organisations" => expected_aggregate_params({
          requested: 10,
          scope: :all_filters,
        })
      }
    }), p.parsed_params)
  end

  it "complain about invalid scope options in aggregate parameters" do
    p = SearchParameterParser.new({
      "aggregate_organisations" => ["10,scope:unknown"],
    }, @schema)

    assert_equal(%{"unknown" is not a valid scope option in aggregate "organisations"}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "complain about a repeated examples option" do
    p = SearchParameterParser.new({
      "aggregate_organisations" => ["10,examples:5,examples:6,example_scope:global"],
    }, @schema)

    assert_equal(%{Too many values (2) for parameter "examples" in aggregate "organisations" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "merge fields from repeated example_fields options" do
    p = SearchParameterParser.new({
      "aggregate_organisations" => ["10,examples:5,example_fields:slug,example_fields:title:link,example_scope:global"],
    }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({
      aggregates: {
        "organisations" => expected_aggregate_params({
          requested: 10,
          examples: 5,
          example_fields: %w(slug title link),
          example_scope: :global,
      }) } }), p.parsed_params)
  end

  it "require the example_scope to be set" do
    p = SearchParameterParser.new({
      "aggregate_organisations" => ["10,examples:5,example_fields:slug:title"],
    }, @schema)

    assert_equal("example_scope parameter must be set to 'query' or 'global' when requesting examples", p.error)
    assert !p.valid?
    assert_equal(expected_params({ aggregates: {} }), p.parsed_params)
  end

  it "allow example_scope to be set to 'query'" do
    p = SearchParameterParser.new({
      "aggregate_organisations" => ["10,examples:5,example_fields:slug:title,example_scope:query"],
    }, @schema)

    assert p.valid?
    assert_equal(expected_params({
      aggregates: {
        "organisations" => expected_aggregate_params({
          requested: 10,
          examples: 5,
          example_fields: %w(slug title),
          example_scope: :query,
        })
      }
    }), p.parsed_params)
  end

  it "complain about an invalid example_scope option" do
    p = SearchParameterParser.new({
      "aggregate_organisations" => ["10,examples:5,example_scope:invalid"],
    }, @schema)

    assert_equal("example_scope parameter must be set to 'query' or 'global' when requesting examples", p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "complain about a repeated example_scope option" do
    p = SearchParameterParser.new({
      "aggregate_organisations" => ["10,examples:5,example_scope:global,example_scope:global"],
    }, @schema)

    assert_equal(%{Too many values (2) for parameter "example_scope" in aggregate "organisations" (must occur at most once)}, p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "validate options in the values for the aggregate parameter" do
    p = SearchParameterParser.new({
      "aggregate_organisations" => ["10,example:5,examples:lots,example_fields:unknown:title"],
    }, @schema)

    assert_equal([
      %{Invalid value "lots" for parameter "examples" in aggregate "organisations" (expected positive integer)},
      %{Some requested fields are not valid return fields: ["unknown"] in parameter "example_fields" in aggregate "organisations"},
      %{Unexpected options in aggregate "organisations": example},
    ].join(". "), p.error)
    assert !p.valid?
    assert_equal(expected_params({}), p.parsed_params)
  end

  it "accept facets as a alias for aggregates" do
    aggregate_p = SearchParameterParser.new({
      "aggregate_organisations" => ["10,examples:5,example_fields:slug:title,example_scope:query"],
    }, @schema)
    facet_p = SearchParameterParser.new({
      "facet_organisations" => ["10,examples:5,example_fields:slug:title,example_scope:query"],
    }, @schema)

    assert aggregate_p.valid?
    assert facet_p.valid?
    assert_equal(aggregate_p.parsed_params['aggregates'], facet_p.parsed_params['facets'])
  end

  it "compalin with facets are used in combination with aggregates" do
    p = SearchParameterParser.new({
      "aggregate_organisations" => ["10"],
      "facet_mainstream_browse_pages" => ["10"],
    }, @schema)

    assert_equal("aggregates can not be used in conjuction with facets, please switch to using aggregates as facets are deprecated.", p.error)
    assert !p.valid?
  end

  it "understand the fields parameter" do
    p = SearchParameterParser.new({ "fields" => %w(title description) }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal(expected_params({ return_fields: %w(title description) }), p.parsed_params)
  end

  it "complain about invalid fields parameters" do
    p = SearchParameterParser.new({ "fields" => %w(title waffle) }, @schema)

    assert_equal("Some requested fields are not valid return fields: [\"waffle\"]", p.error)
    assert !p.valid?
    assert_equal(expected_params({ return_fields: ["title"] }), p.parsed_params)
  end

  it "understand the debug parameter" do
    p = SearchParameterParser.new({ "debug" => ["disable_best_bets,disable_popularity,,unknown_option"] }, @schema)

    assert_equal(%{Unknown debug option "unknown_option"}, p.error)
    assert !p.valid?
    assert_equal expected_params({ debug: { disable_best_bets: true, disable_popularity: true } }), p.parsed_params
  end

  it "merge values from repeated debug parameters" do
    p = SearchParameterParser.new({ "debug" => ["disable_best_bets,explain", "disable_popularity"] }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal expected_params({ debug: { disable_best_bets: true, explain: true, disable_popularity: true } }), p.parsed_params
  end

  it "ignore empty options in the debug parameter" do
    p = SearchParameterParser.new({ "debug" => [",,"] }, @schema)

    assert_equal("", p.error)
    assert p.valid?
    assert_equal expected_params({ debug: {} }), p.parsed_params
  end

  it "understand explain in the debug parameter" do
    p = SearchParameterParser.new({ "debug" => ["explain"] }, @schema)

    assert p.valid?
    assert_equal expected_params({ debug: { explain: true } }), p.parsed_params
  end

  it "understand disable_synonyms in the debug parameter" do
    p = SearchParameterParser.new({ "debug" => ["disable_synonyms"] }, @schema)

    assert p.valid?
    assert_equal expected_params({ debug: { disable_synonyms: true } }), p.parsed_params
  end

  it "understand the test_variant parameter" do
    p = SearchParameterParser.new({ "ab_tests" => ["min_should_match_length:A"] }, @schema)

    assert p.valid?
    assert_equal expected_params({ ab_tests: { min_should_match_length: 'A' } }), p.parsed_params
  end

  it "understand multiple test_variant parameters" do
    p = SearchParameterParser.new({ "ab_tests" => ["min_should_match_length:A,other_test_case:B"] }, @schema)

    assert p.valid?
    assert_equal expected_params({ ab_tests: { min_should_match_length: 'A', other_test_case: 'B' } }), p.parsed_params
  end

  it "complain about invalid test_variant where no variant_type is provided" do
    p = SearchParameterParser.new({ "ab_tests" => ["min_should_match_length"] }, @schema)

    assert !p.valid?
    assert_equal("Invalid ab_tests, missing type \"min_should_match_length\"", p.error)
  end
end
