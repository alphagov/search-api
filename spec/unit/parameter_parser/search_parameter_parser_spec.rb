require 'spec_helper'

RSpec.describe SearchParameterParser do
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
    described_class::TextFieldFilter.new(field_name, values, rejects)
  end

  before do
    @schema = double("combined index schema")
    date_type = double("date type")
    allow(date_type).to receive(:filter_type).and_return("date")
    identifier_type = double("identifier type")
    allow(identifier_type).to receive(:filter_type).and_return("text")
    string_type = double("string type")
    allow(string_type).to receive(:filter_type).and_return(nil)
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
      definition = double("#{field} definition")
      allow(definition).to receive(:type).and_return(type)
      field_definitions[field] = definition
      if type.filter_type
        allowed_filter_fields << field
      end
    }
    allow(@schema).to receive(:field_definitions).and_return(field_definitions)
    allow(@schema).to receive(:allowed_filter_fields).and_return(allowed_filter_fields)
  end

  it "return valid params given nothing" do
    p = described_class.new({}, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "complain about an unknown parameter" do
    p = described_class.new({ "p" => ["extra"] }, @schema)

    expect(p.error).to eq("Unexpected parameters: p")
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "allow the c parameter to be anything" do
    p = described_class.new({ "c" => ["1234567890"] }, @schema)

    expect(p).to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "complain about multiple unknown parameters" do
    p = described_class.new({ "p" => ["extra"], "boo" => ["goose"] }, @schema)

    expect(p.error).to eq("Unexpected parameters: p, boo")
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "understand the start parameter" do
    p = described_class.new({ "start" => ["5"] }, @schema)
    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(start: 5)).to eq(p.parsed_params)
  end

  it "complain about a non-integer start parameter" do
    p = described_class.new({ "start" => ["5.5"] }, @schema)

    expect(p.error).to eq("Invalid value \"5.5\" for parameter \"start\" (expected positive integer)")
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "complain about a negative start parameter" do
    p = described_class.new({ "start" => ["-1"] }, @schema)

    expect(p.error).to eq("Invalid negative value \"-1\" for parameter \"start\" (expected positive integer)")
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "complain about a non-decimal start parameter" do
    p = described_class.new({ "start" => ["x"] }, @schema)

    expect(p.error).to eq("Invalid value \"x\" for parameter \"start\" (expected positive integer)")
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "complain about a repeated start parameter" do
    p = described_class.new({ "start" => %w(2 3) }, @schema)

    expect(%{Too many values (2) for parameter "start" (must occur at most once)}).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params(start: 2)).to eq(p.parsed_params)
  end

  it "understand the count parameter" do
    p = described_class.new({ "count" => ["5"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(count: 5)).to eq(p.parsed_params)
  end

  it "complain about a non-integer count parameter" do
    p = described_class.new({ "count" => ["5.5"] }, @schema)

    expect(p.error).to eq("Invalid value \"5.5\" for parameter \"count\" (expected positive integer)")
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "complain about a negative count parameter" do
    p = described_class.new({ "count" => ["-1"] }, @schema)

    expect(p.error).to eq("Invalid negative value \"-1\" for parameter \"count\" (expected positive integer)")
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "complain about a non-decimal count parameter" do
    p = described_class.new({ "count" => ["x"] }, @schema)

    expect(p.error).to eq("Invalid value \"x\" for parameter \"count\" (expected positive integer)")
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "complain about a repeated count parameter" do
    p = described_class.new({ "count" => %w(2 3) }, @schema)

    expect(%{Too many values (2) for parameter "count" (must occur at most once)}).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params(count: 2)).to eq(p.parsed_params)
  end

  it "complain about an overly large count parameter" do
    p = described_class.new({ "count" => %w(1001) }, @schema)

    expect(%{Maximum result set size (as specified in 'count') is 1000}).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params(count: 10)).to eq(p.parsed_params)
  end

  it "understand the q parameter" do
    p = described_class.new({ "q" => ["search-term"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(query: "search-term")).to eq(p.parsed_params)
  end

  it "complain about a repeated q parameter" do
    p = described_class.new({ "q" => %w(hello world) }, @schema)

    expect(%{Too many values (2) for parameter "q" (must occur at most once)}).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params(query: "hello")).to eq(p.parsed_params)
  end

  it "strip whitespace from the query" do
    p = described_class.new({ "q" => ["cheese "] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(query: "cheese")).to eq(p.parsed_params)
  end

  it "put the query in normalized form" do
    p = described_class.new({ "q" => ["cafe\u0300 "] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(query: "caf\u00e8")).to eq(p.parsed_params)
  end

  it "complain about invalid unicode in the query" do
    p = described_class.new({ "q" => ["\xff"] }, @schema)

    expect(p.error).to eq("Invalid unicode in query")
    expect(p).not_to be_valid
    expect(expected_params(query: nil)).to eq(p.parsed_params)
  end

  it "understand the similar to parameter" do
    p = described_class.new({ "similar_to" => ["/search-term"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(similar_to: "/search-term")).to eq(p.parsed_params)
  end

  it "complain about a repeated similar to parameter" do
    p = described_class.new({ "similar_to" => %w(/hello /world) }, @schema)

    expect(%{Too many values (2) for parameter "similar_to" (must occur at most once)}).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params(similar_to: "/hello")).to eq(p.parsed_params)
  end

  it "strip whitespace from similar to parameter" do
    p = described_class.new({ "similar_to" => ["/cheese "] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(similar_to: "/cheese")).to eq(p.parsed_params)
  end

  it "put the similar to parameter in normalized form" do
    p = described_class.new({ "similar_to" => ["/cafe\u0300 "] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(similar_to: "/caf\u00e8")).to eq(p.parsed_params)
  end

  it "complain about invalid unicode in the similar to parameter" do
    p = described_class.new({ "similar_to" => ["\xff"] }, @schema)

    expect(p.error).to eq("Invalid unicode in similar_to")
    expect(p).not_to be_valid
    expect(expected_params(similar_to: nil)).to eq(p.parsed_params)
  end

  it "complain when both q and similar to parameters are provided" do
    p = described_class.new({ "q" => ["hello"], "similar_to" => ["/world"] }, @schema)

    expect(p.error).to eq("Parameters 'q' and 'similar_to' cannot be used together")
    expect(p).not_to be_valid
    expect(expected_params(query: "hello", similar_to: "/world")).to eq(p.parsed_params)
  end

  it "set the order parameter to nil when the similar to parameter is provided" do
    p = described_class.new({ "similar_to" => ["/hello"], "order" => ["title"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(similar_to: "/hello")).to eq(p.parsed_params)
  end

  it "understand filter paramers" do
    p = described_class.new({ "filter_organisations" => ["hm-magic"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(
      hash_including(filters: [
        text_filter("organisations", ["hm-magic"])
      ])
    ).to eq(
      p.parsed_params,
    )
  end

  it "understand reject paramers" do
    p = described_class.new({ "reject_organisations" => ["hm-magic"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(
      hash_including(filters: [
        text_filter("organisations", ["hm-magic"], true)
      ])
    ).to eq(
      p.parsed_params,
    )
  end

  it "understand some rejects and some filter paramers" do
    p = described_class.new({
      "reject_organisations" => ["hm-magic"],
      "filter_mainstream_browse_pages" => ["cheese"],
    }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(
      hash_including(filters: [
        text_filter("mainstream_browse_pages", ["cheese"]),
        text_filter("organisations", ["hm-magic"], true),
      ])
    ).to eq(
      p.parsed_params,
    )
  end

  it "understand multiple filter paramers" do
    p = described_class.new({ "filter_organisations" => ["hm-magic", "hmrc"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(
      expected_params(
        filters: [
          text_filter("organisations", [
              "hm-magic",
              "hmrc",
            ]
          )
        ],
      )
    ).to eq(
      p.parsed_params,
    )
  end

  it "understand filter for missing field" do
    p = described_class.new({ "filter_organisations" => ["_MISSING"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid

    filters = p.parsed_params[:filters]
    expect(filters.size).to eq(1)
    expect(filters[0].field_name).to eq("organisations")
    expect(true).to eq(filters[0].include_missing)
    expect(filters[0].values).to eq([])
  end

  it "understand filter for missing field or specific value" do
    p = described_class.new({ "filter_organisations" => %w(_MISSING hmrc) }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid

    filters = p.parsed_params[:filters]
    expect(filters.size).to eq(1)
    expect(filters[0].field_name).to eq("organisations")
    expect(true).to eq(filters[0].include_missing)
    expect(filters[0].values).to eq(["hmrc"])
  end

  it "complain about disallowed filter fields" do
    p = described_class.new(
      {
        "filter_spells" => ["levitation"],
        "filter_organisations" => ["hm-magic"]
      },
      @schema,
    )

    expect(%{"spells" is not a valid filter field}).to eq(p.error)
    expect(p).not_to be_valid
    expect(
      expected_params(filters: [text_filter("organisations", ["hm-magic"])])
    ).to eq(
      p.parsed_params,
    )
  end

  it "complain about disallowed reject fields" do
    p = described_class.new(
      {
        "reject_spells" => ["levitation"],
        "reject_organisations" => ["hm-magic"]
      },
      @schema,
    )

    expect(%{"spells" is not a valid reject field}).to eq(p.error)
    expect(p).not_to be_valid
    expect(
      expected_params(filters: [text_filter("organisations", ["hm-magic"], true)])
    ).to eq(
      p.parsed_params,
    )
  end

  # TODO: this is deprecated behaviour
  it "rewrite document_type filter to  type filter" do
    parser = described_class.new(
      { "filter_document_type" => ["cma_case"] },
      @schema,
    )

    expect(
      hash_including(filters: [text_filter("_type", ["cma_case"])])
    ).to eq(
      parser.parsed_params,
    )
  end

  context "when the filter field is a date type" do
    it "include the type in return value of #parsed params" do
      params = {
        "filter_document_type" => ["cma_case"],
        "filter_opened_date" => "from:2014-04-01 05:08,to:2014-04-02 17:43:12",
      }

      parser = described_class.new(params, @schema)

      expect(parser).to be_valid, "Parameters should be valid: #{parser.errors}"

      opened_date_filter = parser.parsed_params.fetch(:filters)
        .find { |filter| filter.field_name == "opened_date" }

      expect(opened_date_filter.values.first.from)
        .to eq(DateTime.new(2014, 4, 1, 5, 8))
      expect(opened_date_filter.values.first.to)
        .to eq(DateTime.new(2014, 4, 2, 17, 43, 12))
    end

    it "understand date filter for missing field or specific value" do
      parser = described_class.new({
        "filter_document_type" => ["cma_case"],
        "filter_opened_date" => ["_MISSING", "from:2014-04-01 00:00,to:2014-04-02 00:00"],
      }, @schema)

      expect(parser.error).to eq("")
      expect(parser).to be_valid

      opened_date_filter = parser.parsed_params.fetch(:filters)
        .find { |filter| filter.field_name == "opened_date" }

      expect(opened_date_filter.field_name).to eq("opened_date")
      expect(true).to eq(opened_date_filter.include_missing)

      expect(opened_date_filter.values.first.from)
        .to eq(Date.new(2014, 4, 1))
      expect(opened_date_filter.values.first.to)
        .to eq(Date.new(2014, 4, 2))
    end

    it "includes the whole day if time is omitted" do
      params = {
        "filter_document_type" => ["cma_case"],
        "filter_public_timestamp" => "from:2017-06-05,to:2017-06-08",
      }

      parser = described_class.new(params, @schema)

      expect(parser).to be_valid, "Parameters should be valid: #{parser.errors}"

      opened_date_filter = parser.parsed_params.fetch(:filters)
        .find { |filter| filter.field_name == "public_timestamp" }

      expect(opened_date_filter.values.first.from)
        .to eq(DateTime.new(2017, 6, 5, 0, 0, 0))
      expect(opened_date_filter.values.first.to)
        .to eq(DateTime.new(2017, 6, 8, 23, 59, 59))
    end
  end

  context "filtering a date field with invalid parameters" do
    it "does not filter on date if date is invalid" do
      params = {
        "filter_document_type" => ["cma_case"],
        "filter_opened_date" => "from:2014-bananas-01 00:00,to:2014-04-02 00:00",
      }

      parser = described_class.new(params, @schema)

      opened_date_filter = parser.parsed_params.fetch(:filters)
        .find { |filter| filter.field_name == "opened_date" }

      expect(opened_date_filter).to be_nil
    end

    it "does not filter on date if the filter parameter name is invalid" do
      params = {
        "filter_document_type" => ["cma_case"],
        "filter_opened_date" => "some_invalid_parameter:2014-04-01",
      }

      parser = described_class.new(params, @schema)

      opened_date_filter = parser.parsed_params.fetch(:filters)
        .find { |filter| filter.field_name == "opened_date" }

      expect(opened_date_filter).to be_nil
    end
  end

  it "understand an ascending sort" do
    p = described_class.new({ "order" => ["public_timestamp"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params({ order: %w(public_timestamp asc) })).to eq(p.parsed_params)
  end

  it "understand a descending sort" do
    p = described_class.new({ "order" => ["-public_timestamp"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params({ order: %w(public_timestamp desc) })).to eq(p.parsed_params)
  end

  it "complain about disallowed sort fields" do
    p = described_class.new({ "order" => ["spells"] }, @schema)

    expect(%{"spells" is not a valid sort field}).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "complain about disallowed descending sort fields" do
    p = described_class.new({ "order" => ["-spells"] }, @schema)

    expect(%{"spells" is not a valid sort field}).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "complain about a repeated sort parameter" do
    p = described_class.new({ "order" => %w(public_timestamp something_else) }, @schema)

    expect(%{Too many values (2) for parameter "order" (must occur at most once)}).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params(order: %w(public_timestamp asc))).to eq(p.parsed_params)
  end

  it "understand a aggregate field" do
    p = described_class.new({ "aggregate_organisations" => ["10"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(
      expected_params(aggregates: { "organisations" => expected_aggregate_params(requested: 10) })
    ).to eq(p.parsed_params)
  end

  it "understand multiple aggregate fields" do
    p = described_class.new({
      "aggregate_organisations" => ["10"],
      "aggregate_mainstream_browse_pages" => ["5"],
    }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(
      expected_params(
        aggregates: {
          "organisations" => expected_aggregate_params(requested: 10),
          "mainstream_browse_pages" => expected_aggregate_params(requested: 5)
        }
      )
    ).to eq(p.parsed_params)
  end

  it "complain about disallowed aggregates fields" do
    p = described_class.new({
      "aggregate_spells" => ["10"],
      "aggregate_organisations" => ["10"],
    }, @schema)

    expect(%{"spells" is not a valid aggregate field}).to eq(p.error)
    expect(p).not_to be_valid
    expect(
      expected_params(aggregates: { "organisations" => expected_aggregate_params(requested: 10) })
    ).to eq(p.parsed_params)
  end

  it "complain about invalid values for aggregate parameter" do
    p = described_class.new({
      "aggregate_spells" => ["levitation"],
      "aggregate_organisations" => ["magic"],
    }, @schema)

    expect(%{"spells" is not a valid aggregate field. Invalid value "magic" for first parameter for aggregate "organisations" (expected positive integer)}).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "complain about empty values for aggregate parameter" do
    p = described_class.new({ "aggregate_organisations" => [""] }, @schema)

    expect(%{Invalid value "" for first parameter for aggregate "organisations" (expected positive integer)}).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "complain about a repeated aggregate parameter" do
    p = described_class.new({ "aggregate_organisations" => %w(5 6) }, @schema)

    expect(%{Too many values (2) for parameter "aggregate_organisations" (must occur at most once)}).to eq(p.error)
    expect(p).not_to be_valid
    expect(
      expected_params(aggregates: { "organisations" => expected_aggregate_params(requested: 5) })
    ).to eq(p.parsed_params)
  end

  it "allow options in the values for the aggregate parameter" do
    p = described_class.new({
      "aggregate_organisations" => ["10,examples:5,example_fields:slug:title,example_scope:global"],
    }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(
      aggregates: {
        "organisations" => expected_aggregate_params(
          requested: 10,
          examples: 5,
          example_fields: %w(slug title),
          example_scope: :global,
      ) }
    )).to eq(p.parsed_params)
  end

  it "understand the order option in aggregate parameters" do
    p = described_class.new({
      "aggregate_organisations" => ["10,order:filtered:value.link:-count"],
    }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(
      aggregates: {
        "organisations" => expected_aggregate_params(
          requested: 10,
          order: [[:filtered, 1], [:"value.link", 1], [:count, -1]],
      ) }
    )).to eq(p.parsed_params)
  end

  it "complain about invalid order options in aggregate parameters" do
    p = described_class.new({
      "aggregate_organisations" => ["10,order:filt:value.unknown"],
    }, @schema)

    expect(%{"filt" is not a valid sort option in aggregate "organisations". "value.unknown" is not a valid sort option in aggregate "organisations"}).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end


  it "handle repeated order options in aggregate parameters" do
    p = described_class.new({
      "aggregate_organisations" => ["10,order:filtered,order:value.link:-count"],
    }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(
      aggregates: {
        "organisations" => expected_aggregate_params(
          requested: 10,
          order: [[:filtered, 1], [:"value.link", 1], [:count, -1]],
      ) }
    )).to eq(p.parsed_params)
  end

  it "understand the scope option in aggregate parameters" do
    p = described_class.new({
      "aggregate_organisations" => ["10,scope:all_filters"],
    }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(
      aggregates: {
        "organisations" => expected_aggregate_params(
          requested: 10,
          scope: :all_filters,
      ) }
    )).to eq(p.parsed_params)
  end

  it "complain about invalid scope options in aggregate parameters" do
    p = described_class.new({
      "aggregate_organisations" => ["10,scope:unknown"],
    }, @schema)

    expect(%{"unknown" is not a valid scope option in aggregate "organisations"}).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "complain about a repeated examples option" do
    p = described_class.new({
      "aggregate_organisations" => ["10,examples:5,examples:6,example_scope:global"],
    }, @schema)

    expect(%{Too many values (2) for parameter "examples" in aggregate "organisations" (must occur at most once)}).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "merge fields from repeated example fields options" do
    p = described_class.new({
      "aggregate_organisations" => ["10,examples:5,example_fields:slug,example_fields:title:link,example_scope:global"],
    }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(
      aggregates: {
        "organisations" => expected_aggregate_params(
          requested: 10,
          examples: 5,
          example_fields: %w(slug title link),
          example_scope: :global,
      ) }
    )).to eq(p.parsed_params)
  end

  it "require the example scope to be set" do
    p = described_class.new({
      "aggregate_organisations" => ["10,examples:5,example_fields:slug:title"],
    }, @schema)

    expect(p.error).to eq("example_scope parameter must be set to 'query' or 'global' when requesting examples")
    expect(p).not_to be_valid
    expect(expected_params({ aggregates: {} })).to eq(p.parsed_params)
  end

  it "allow example scope to be set to 'query'" do
    p = described_class.new({
      "aggregate_organisations" => ["10,examples:5,example_fields:slug:title,example_scope:query"],
    }, @schema)

    expect(p).to be_valid
    expect(expected_params(
      aggregates: {
        "organisations" => expected_aggregate_params(
          requested: 10,
          examples: 5,
          example_fields: %w(slug title),
          example_scope: :query,
      ) }
    )).to eq(p.parsed_params)
  end

  it "complain about an invalid example scope option" do
    p = described_class.new({
      "aggregate_organisations" => ["10,examples:5,example_scope:invalid"],
    }, @schema)

    expect(p.error).to eq("example_scope parameter must be set to 'query' or 'global' when requesting examples")
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "complain about a repeated example scope option" do
    p = described_class.new({
      "aggregate_organisations" => ["10,examples:5,example_scope:global,example_scope:global"],
    }, @schema)

    expect(%{Too many values (2) for parameter "example_scope" in aggregate "organisations" (must occur at most once)}).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "validate options in the values for the aggregate parameter" do
    p = described_class.new({
      "aggregate_organisations" => ["10,example:5,examples:lots,example_fields:unknown:title"],
    }, @schema)

    expect([
      %{Invalid value "lots" for parameter "examples" in aggregate "organisations" (expected positive integer)},
      %{Some requested fields are not valid return fields: ["unknown"] in parameter "example_fields" in aggregate "organisations"},
      %{Unexpected options in aggregate "organisations": example},
    ].join(". ")).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params({})).to eq(p.parsed_params)
  end

  it "accept facets as a alias for aggregates" do
    aggregate_p = described_class.new({
      "aggregate_organisations" => ["10,examples:5,example_fields:slug:title,example_scope:query"],
    }, @schema)
    facet_p = described_class.new({
      "facet_organisations" => ["10,examples:5,example_fields:slug:title,example_scope:query"],
    }, @schema)

    expect(aggregate_p).to be_valid
    expect(facet_p).to be_valid
    expect(aggregate_p.parsed_params['aggregates']).to eq(facet_p.parsed_params['facets'])
  end

  it "compalin with facets are used in combination with aggregates" do
    p = described_class.new({
      "aggregate_organisations" => ["10"],
      "facet_mainstream_browse_pages" => ["10"],
    }, @schema)

    expect(
      "aggregates can not be used in conjuction with facets, please switch to using aggregates as facets are deprecated."
    ).to eq(p.error)
    expect(p).not_to be_valid
  end

  it "understand the fields parameter" do
    p = described_class.new({ "fields" => %w(title description) }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(return_fields: %w(title description))).to eq(p.parsed_params)
  end

  it "complain about invalid fields parameters" do
    p = described_class.new({ "fields" => %w(title waffle) }, @schema)

    expect(p.error).to eq("Some requested fields are not valid return fields: [\"waffle\"]")
    expect(p).not_to be_valid
    expect(expected_params(return_fields: ["title"])).to eq(p.parsed_params)
  end

  it "understand the debug parameter" do
    p = described_class.new({ "debug" => ["disable_best_bets,disable_popularity,,unknown_option"] }, @schema)

    expect(%{Unknown debug option "unknown_option"}).to eq(p.error)
    expect(p).not_to be_valid
    expect(expected_params(debug: { disable_best_bets: true, disable_popularity: true })).to eq(p.parsed_params)
  end

  it "merge values from repeated debug parameters" do
    p = described_class.new({ "debug" => ["disable_best_bets,explain", "disable_popularity"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(debug: { disable_best_bets: true, explain: true, disable_popularity: true })).to eq(p.parsed_params)
  end

  it "ignore empty options in the debug parameter" do
    p = described_class.new({ "debug" => [",,"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(expected_params(debug: {})).to eq(p.parsed_params)
  end

  it "understand explain in the debug parameter" do
    p = described_class.new({ "debug" => ["explain"] }, @schema)

    expect(p).to be_valid
    expect(expected_params(debug: { explain: true })).to eq(p.parsed_params)
  end

  it "understand disable synonyms in the debug parameter" do
    p = described_class.new({ "debug" => ["disable_synonyms"] }, @schema)

    expect(p).to be_valid
    expect(expected_params(debug: { disable_synonyms: true })).to eq(p.parsed_params)
  end

  it "understand the test variant parameter" do
    p = described_class.new({ "ab_tests" => ["min_should_match_length:A"] }, @schema)

    expect(p).to be_valid
    expect(expected_params(ab_tests: { min_should_match_length: 'A' })).to eq(p.parsed_params)
  end

  it "understand multiple test variant parameters" do
    p = described_class.new({ "ab_tests" => ["min_should_match_length:A,other_test_case:B"] }, @schema)

    expect(p).to be_valid
    expect(expected_params(ab_tests: { min_should_match_length: 'A', other_test_case: 'B' })).to eq(p.parsed_params)
  end

  it "complain about invalid test variant where no variant type is provided" do
    p = described_class.new({ "ab_tests" => ["min_should_match_length"] }, @schema)

    expect(p).not_to be_valid
    expect(p.error).to eq("Invalid ab_tests, missing type \"min_should_match_length\"")
  end
end
