require 'spec_helper'

RSpec.describe SearchParameterParser do
  def cluster_with_key(key)
    satisfy { |c| c.key == key }
  end

  def expected_params(params)
    {
      start: 0,
      count: 10,
      query: nil,
      parsed_query: nil,
      similar_to: nil,
      cluster: cluster_with_key(Clusters.default_cluster.key),
      search_config: instance_of(SearchConfig),
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

  def text_filter(field_name, values, operation = :filter, multivalue_query = :any)
    described_class::TextFieldFilter.new(field_name, values, operation, multivalue_query)
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

  it "returns valid params given nothing" do
    p = described_class.new({}, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "complains about an unknown parameter" do
    p = described_class.new({ "p" => ["extra"] }, @schema)

    expect(p.error).to eq("Unexpected parameters: p")
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "allows the c parameter to be anything" do
    p = described_class.new({ "c" => ["1234567890"] }, @schema)

    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "understands the search_cluster_query A/B parameter" do
    cluster = Clusters.active.sample # random cluster
    p = described_class.new({ "ab_tests" => ["search_cluster_query:#{cluster.key}"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(
      expected_params(
        ab_tests: { search_cluster_query: cluster.key },
        cluster: cluster_with_key(cluster.key),
       )
    )
  end

  it "uses the default cluster if the search_cluster_query A/B parameter is not set" do
    p = described_class.new({ "ab_tests" => [] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(cluster: cluster_with_key(Clusters.default_cluster.key)))
  end

  it "complains about invalid search_cluster_query A/B parameters" do
    p = described_class.new({ "ab_tests" => ["search_cluster_query:invalid"] }, @schema)

    expect(p.error).to eq(%{Invalid cluster. Accepted values: #{Clusters.active.map(&:key).join(', ')}})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(
      expected_params(
        ab_tests: { search_cluster_query: "invalid" },
        cluster: cluster_with_key(Clusters.default_cluster.key),
      )
     )
  end

  it "complain about multiple unknown parameters" do
    p = described_class.new({ "p" => ["extra"], "boo" => ["goose"] }, @schema)

    expect(p.error).to eq("Unexpected parameters: p, boo")
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "understands the start parameter" do
    p = described_class.new({ "start" => ["5"] }, @schema)
    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(start: 5))
  end

  it "complains about a non-integer start parameter" do
    p = described_class.new({ "start" => ["5.5"] }, @schema)

    expect(p.error).to eq("Invalid value \"5.5\" for parameter \"start\" (expected positive integer)")
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "complains about a negative start parameter" do
    p = described_class.new({ "start" => ["-1"] }, @schema)

    expect(p.error).to eq("Invalid negative value \"-1\" for parameter \"start\" (expected positive integer)")
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "complains about a non-decimal start parameter" do
    p = described_class.new({ "start" => ["x"] }, @schema)

    expect(p.error).to eq("Invalid value \"x\" for parameter \"start\" (expected positive integer)")
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "complains about a repeated start parameter" do
    p = described_class.new({ "start" => %w(2 3) }, @schema)

    expect(p.error).to eq(%{Too many values (2) for parameter "start" (must occur at most once)})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params(start: 2))
  end

  it "complains about a start parameter that is too large" do
    p = described_class.new({ "start" => %w(999999) }, @schema)

    expect(p.error).to eq("Maximum result set start point (as specified in 'start') is 900000")
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params(start: 0))
  end

  it "understands the count parameter" do
    p = described_class.new({ "count" => ["5"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(count: 5))
  end

  it "complains about a non-integer count parameter" do
    p = described_class.new({ "count" => ["5.5"] }, @schema)

    expect(p.error).to eq("Invalid value \"5.5\" for parameter \"count\" (expected positive integer)")
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "complains about a negative count parameter" do
    p = described_class.new({ "count" => ["-1"] }, @schema)

    expect(p.error).to eq("Invalid negative value \"-1\" for parameter \"count\" (expected positive integer)")
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "complains about a non-decimal count parameter" do
    p = described_class.new({ "count" => ["x"] }, @schema)

    expect(p.error).to eq("Invalid value \"x\" for parameter \"count\" (expected positive integer)")
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "complains about a repeated count parameter" do
    p = described_class.new({ "count" => %w(2 3) }, @schema)

    expect(p.error).to eq(%{Too many values (2) for parameter "count" (must occur at most once)})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params(count: 2))
  end

  it "complains about an overly large count parameter" do
    p = described_class.new({ "count" => %w(1501) }, @schema)

    expect(p.error).to eq(%{Maximum result set size (as specified in 'count') is 1500})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params(count: 10))
  end

  it "understands the q parameter" do
    p = described_class.new({ "q" => ["search-term"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(query: "search-term", parsed_query: { quoted: [], unquoted: "search-term" }))
  end

  it "complains when the q parameter is too long" do
    max_length = described_class::MAX_QUERY_LENGTH
    long_query = "a" * max_length
    too_long_query = "1234567890#{long_query}"
    p = described_class.new({ "q" => [too_long_query] }, @schema)

    expect(p.error).to eq(%{Query exceeds the maximum allowed length})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params(query: too_long_query, parsed_query: { quoted: [], unquoted: too_long_query }))
  end

  it "complains about a repeated q parameter" do
    p = described_class.new({ "q" => %w(hello world) }, @schema)

    expect(p.error).to eq(%{Too many values (2) for parameter "q" (must occur at most once)})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params(query: "hello", parsed_query: { quoted: [], unquoted: "hello" }))
  end

  it "strips whitespace from the query" do
    p = described_class.new({ "q" => ["cheese "] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(query: "cheese", parsed_query: { quoted: [], unquoted: "cheese" }))
  end

  it "puts the query in normalized form" do
    p = described_class.new({ "q" => ["cafe\u0300 "] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(query: "caf\u00e8", parsed_query: { quoted: [], unquoted: "caf\u00e8" }))
  end

  it "parses quoted queries" do
    p = described_class.new({ "q" => ['"hello world"'] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(query: '"hello world"', parsed_query: { quoted: ['hello world'], unquoted: "" }))
  end

  it "parses mixed quoted/unquoted queries (simple)" do
    p = described_class.new({ "q" => ['"hello world" foo bar'] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(query: '"hello world" foo bar', parsed_query: { quoted: ['hello world'], unquoted: "foo bar" }))
  end

  it "parses mixed quoted/unquoted queries (complex)" do
    p = described_class.new({ "q" => ['"hello world" foo "bar" bat "baz" qux'] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(query: '"hello world" foo "bar" bat "baz" qux', parsed_query: { quoted: ['hello world', 'bar', 'baz'], unquoted: "foo bat qux" }))
  end

  it "complains about invalid unicode in the query" do
    p = described_class.new({ "q" => ["\xff"] }, @schema)

    expect(p.error).to eq("Invalid unicode in query")
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params(query: nil))
  end

  it "understands the similar_to parameter" do
    p = described_class.new({ "similar_to" => ["/search-term"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(similar_to: "/search-term"))
  end

  it "complains about a repeated similar_to parameter" do
    p = described_class.new({ "similar_to" => %w(/hello /world) }, @schema)

    expect(p.error).to eq(%{Too many values (2) for parameter "similar_to" (must occur at most once)})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params(similar_to: "/hello"))
  end

  it "strips whitespace from similar_to parameter" do
    p = described_class.new({ "similar_to" => ["/cheese "] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(similar_to: "/cheese"))
  end

  it "puts the similar_to parameter in normalized form" do
    p = described_class.new({ "similar_to" => ["/cafe\u0300 "] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(similar_to: "/caf\u00e8"))
  end

  it "complains about invalid unicode in the similar_to parameter" do
    p = described_class.new({ "similar_to" => ["\xff"] }, @schema)

    expect(p.error).to eq("Invalid unicode in similar_to")
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params(similar_to: nil))
  end

  it "complains when both q and similar_to parameters are provided" do
    p = described_class.new({ "q" => ["hello"], "similar_to" => ["/world"] }, @schema)

    expect(p.error).to eq("Parameters 'q' and 'similar_to' cannot be used together")
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params(query: "hello", similar_to: "/world", parsed_query: { quoted: [], unquoted: "hello" }))
  end

  it "sets the order parameter to nil when the similar_to parameter is provided" do
    p = described_class.new({ "similar_to" => ["/hello"], "order" => ["title"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(similar_to: "/hello"))
  end

  it "understands filter paramers" do
    p = described_class.new({ "filter_organisations" => ["hm-magic"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params[:filters]).to eq(
      [text_filter("organisations", ["hm-magic"])]
    )
  end

  it "understands reject paramers" do
    p = described_class.new({ "reject_organisations" => ["hm-magic"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params[:filters]).to eq(
      [text_filter("organisations", ["hm-magic"], :reject, :any)]
    )
  end

  it "understands reject_any paramers" do
    p = described_class.new({ "reject_any_organisations" => ["hm-magic"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params[:filters]).to eq(
      [text_filter("organisations", ["hm-magic"], :reject, :any)]
                                         )
  end

  it "understands reject_all paramers" do
    p = described_class.new({ "reject_all_organisations" => ["hm-magic"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params[:filters]).to eq(
      [text_filter("organisations", ["hm-magic"], :reject, :all)]
                                         )
  end

  it "understands some rejects and some filter paramers" do
    p = described_class.new({
      "reject_organisations" => ["hm-magic"],
      "filter_all_mainstream_browse_pages" => %w[cheese],
      "filter_any_slug" => ["/slug1", "/slug2"],
      "reject_all_link" => ["/link"],
    }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params[:filters]).to match_array([
        text_filter("organisations", ["hm-magic"], :reject, :any),
        text_filter("mainstream_browse_pages", %w[cheese], :filter, :all),
        text_filter("slug", ["/slug1", "/slug2"], :filter, :any),
        text_filter("link", ["/link"], :reject, :all)
      ])
  end

  it "understands multiple filter paramers" do
    p = described_class.new({ "filter_organisations" => ["hm-magic", "hmrc"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(
      expected_params(
        filters: [
          text_filter("organisations", [
              "hm-magic",
              "hmrc",
            ]
          )
        ],
      )
    )
  end

  it "understands filter for missing field" do
    p = described_class.new({ "filter_organisations" => ["_MISSING"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid

    filters = p.parsed_params[:filters]
    expect(filters.size).to eq(1)
    expect(filters[0].field_name).to eq("organisations")
    expect(filters[0].include_missing).to be true
    expect(filters[0].values).to be_empty
  end

  it "understands filter for missing field or specific value" do
    p = described_class.new({ "filter_organisations" => %w(_MISSING hmrc) }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid

    filters = p.parsed_params[:filters]
    expect(filters.size).to eq(1)
    expect(filters[0].field_name).to eq("organisations")
    expect(filters[0].include_missing).to be true
    expect(filters[0].values).to eq(["hmrc"])
  end

  it "complains about disallowed filter fields" do
    p = described_class.new(
      {
        "filter_spells" => ["levitation"],
        "filter_organisations" => ["hm-magic"]
      },
      @schema,
    )

    expect(p.error).to eq(%{"spells" is not a valid filter field})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(
      expected_params(filters: [text_filter("organisations", %w[hm-magic])])
    )
  end

  it "complains about disallowed reject fields" do
    p = described_class.new(
      {
        "reject_spells" => ["levitation"],
        "reject_organisations" => ["hm-magic"]
      },
      @schema,
    )

    expect(p.error).to eq(%{"spells" is not a valid reject field})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(
      expected_params(filters: [text_filter("organisations", %w[hm-magic], :reject)])
    )
  end

  # TODO: this is deprecated behaviour
  it "rewrites a document_type filter to a _type filter" do
    parser = described_class.new(
      { "filter_document_type" => ["cma_case"] },
      @schema,
    )

    expect(parser.parsed_params[:filters]).to eq(
      [text_filter("document_type", %w[cma_case])]
    )
  end

  context "when the filter field is a date type" do
    it "includes the type in return value of #parsed params" do
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

    it "understands a date filter for a missing value or a specific value" do
      parser = described_class.new({
        "filter_document_type" => ["cma_case"],
        "filter_opened_date" => ["_MISSING", "from:2014-04-01 00:00,to:2014-04-02 00:00"],
      }, @schema)

      expect(parser.error).to eq("")
      expect(parser).to be_valid

      opened_date_filter = parser.parsed_params.fetch(:filters)
        .find { |filter| filter.field_name == "opened_date" }

      expect(opened_date_filter.field_name).to eq("opened_date")
      expect(opened_date_filter.include_missing).to be true

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
    it "does not filter on date if the date is invalid" do
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

  it "understands an ascending sort" do
    p = described_class.new({ "order" => ["public_timestamp"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params({ order: %w(public_timestamp asc) }))
  end

  it "understands a descending sort" do
    p = described_class.new({ "order" => ["-public_timestamp"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params({ order: %w(public_timestamp desc) }))
  end

  it "complains about disallowed sort fields" do
    p = described_class.new({ "order" => ["spells"] }, @schema)

    expect(p.error).to eq(%{"spells" is not a valid sort field})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "complains about disallowed descending sort fields" do
    p = described_class.new({ "order" => ["-spells"] }, @schema)

    expect(p.error).to eq(%{"spells" is not a valid sort field})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "complains about a repeated sort parameter" do
    p = described_class.new({ "order" => %w(public_timestamp something_else) }, @schema)

    expect(p.error).to eq(%{Too many values (2) for parameter "order" (must occur at most once)})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params(order: %w(public_timestamp asc)))
  end

  it "understands a aggregate field" do
    p = described_class.new({ "aggregate_organisations" => ["10"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(
      expected_params(aggregates: { "organisations" => expected_aggregate_params(requested: 10) })
    )
  end

  it "understands multiple aggregate fields" do
    p = described_class.new({
      "aggregate_organisations" => ["10"],
      "aggregate_mainstream_browse_pages" => ["5"],
    }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(
      expected_params(
        aggregates: {
          "organisations" => expected_aggregate_params(requested: 10),
          "mainstream_browse_pages" => expected_aggregate_params(requested: 5)
        }
      )
    )
  end

  it "complains about disallowed aggregates fields" do
    p = described_class.new({
      "aggregate_spells" => ["10"],
      "aggregate_organisations" => ["10"],
    }, @schema)

    expect(p.error).to eq(%{"spells" is not a valid aggregate field})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(
      expected_params(aggregates: { "organisations" => expected_aggregate_params(requested: 10) })
    )
  end

  it "complains about invalid values for aggregate parameter" do
    p = described_class.new({
      "aggregate_spells" => ["levitation"],
      "aggregate_organisations" => ["magic"],
    }, @schema)

    expect(p.error).to eq(%{"spells" is not a valid aggregate field. Invalid value "magic" for first parameter for aggregate "organisations" (expected positive integer)})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "complains about empty values for aggregate parameter" do
    p = described_class.new({ "aggregate_organisations" => [""] }, @schema)

    expect(p.error).to eq(%{Invalid value "" for first parameter for aggregate "organisations" (expected positive integer)})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "complains about a repeated aggregate parameter" do
    p = described_class.new({ "aggregate_organisations" => %w(5 6) }, @schema)

    expect(p.error).to eq(%{Too many values (2) for parameter "aggregate_organisations" (must occur at most once)})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(
      expected_params(aggregates: { "organisations" => expected_aggregate_params(requested: 5) })
    )
  end

  it "allows options in the values for the aggregate parameter" do
    p = described_class.new({
      "aggregate_organisations" => ["10,examples:5,example_fields:slug:title,example_scope:global"],
    }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(
      expected_params(
        aggregates: {
          "organisations" => expected_aggregate_params(
            requested: 10,
            examples: 5,
            example_fields: %w(slug title),
            example_scope: :global,
          )
        }
    )
)
  end

  it "understands the order option in aggregate parameters" do
    p = described_class.new({
      "aggregate_organisations" => ["10,order:filtered:value.link:-count"],
    }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(
                                       aggregates: {
                                         "organisations" => expected_aggregate_params(
                                           requested: 10,
                                           order: [[:filtered, 1], [:"value.link", 1], [:count, -1]],
                                       )
                                 }
    ))
  end

  it "complains about invalid order options in aggregate parameters" do
    p = described_class.new({
      "aggregate_organisations" => ["10,order:filt:value.unknown"],
    }, @schema)

    expect(p.error).to eq(%{"filt" is not a valid sort option in aggregate "organisations". "value.unknown" is not a valid sort option in aggregate "organisations"})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end


  it "handles repeated order options in aggregate parameters" do
    p = described_class.new({
      "aggregate_organisations" => ["10,order:filtered,order:value.link:-count"],
    }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(
                                       aggregates: {
                                         "organisations" => expected_aggregate_params(
                                           requested: 10,
                                           order: [[:filtered, 1], [:"value.link", 1], [:count, -1]],
                                         )
                                       }
    ))
  end

  it "understands the scope option in aggregate parameters" do
    p = described_class.new({
      "aggregate_organisations" => ["10,scope:all_filters"],
    }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(
                                       aggregates: {
                                         "organisations" => expected_aggregate_params(
                                           requested: 10,
                                           scope: :all_filters,
                                         )
                                       }
    ))
  end

  it "complains about invalid scope options in aggregate parameters" do
    p = described_class.new({
      "aggregate_organisations" => ["10,scope:unknown"],
    }, @schema)

    expect(p.error).to eq(%{"unknown" is not a valid scope option in aggregate "organisations"})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "complains about a repeated examples option" do
    p = described_class.new({
      "aggregate_organisations" => ["10,examples:5,examples:6,example_scope:global"],
    }, @schema)

    expect(%{Too many values (2) for parameter "examples" in aggregate "organisations" (must occur at most once)}).to eq(p.error)
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "merges fields from repeated example fields options" do
    p = described_class.new({
      "aggregate_organisations" => ["10,examples:5,example_fields:slug,example_fields:title:link,example_scope:global"],
    }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(
                                       aggregates: {
                                         "organisations" => expected_aggregate_params(
                                           requested: 10,
                                           examples: 5,
                                           example_fields: %w(slug title link),
                                           example_scope: :global,
                                         )
                                       }
    ))
  end

  it "requires the example scope to be set" do
    p = described_class.new({
      "aggregate_organisations" => ["10,examples:5,example_fields:slug:title"],
    }, @schema)

    expect(p.error).to eq("example_scope parameter must be set to 'query' or 'global' when requesting examples")
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({ aggregates: {} }))
  end

  it "allows example scope to be set to 'query'" do
    p = described_class.new({
      "aggregate_organisations" => ["10,examples:5,example_fields:slug:title,example_scope:query"],
    }, @schema)

    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(
                                       aggregates: {
                                         "organisations" => expected_aggregate_params(
                                           requested: 10,
                                           examples: 5,
                                           example_fields: %w(slug title),
                                           example_scope: :query,
                                         )
                                       }
    ))
  end

  it "complains about an invalid example scope option" do
    p = described_class.new({
      "aggregate_organisations" => ["10,examples:5,example_scope:invalid"],
    }, @schema)

    expect(p.error).to eq("example_scope parameter must be set to 'query' or 'global' when requesting examples")
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "complains about a repeated example scope option" do
    p = described_class.new({
      "aggregate_organisations" => ["10,examples:5,example_scope:global,example_scope:global"],
    }, @schema)

    expect(p.error).to eq(%{Too many values (2) for parameter "example_scope" in aggregate "organisations" (must occur at most once)})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "validates options in the values for the aggregate parameter" do
    p = described_class.new({
      "aggregate_organisations" => ["10,example:5,examples:lots,example_fields:unknown:title"],
    }, @schema)

    expect(p.error).to eq([
      %{Invalid value "lots" for parameter "examples" in aggregate "organisations" (expected positive integer)},
      %{Some requested fields are not valid return fields: ["unknown"] in parameter "example_fields" in aggregate "organisations"},
      %{Unexpected options in aggregate "organisations": example},
    ].join(". "))
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params({}))
  end

  it "accepts facets as a alias for aggregates" do
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

  it "compalins with facets are used in combination with aggregates" do
    p = described_class.new({
      "aggregate_organisations" => %w[10],
      "facet_mainstream_browse_pages" => ["10"],
    }, @schema)

    expect(p.error).to eq(
      "aggregates can not be used in conjuction with facets, please switch to using aggregates as facets are deprecated."
    )
    expect(p).not_to be_valid
  end

  it "understands the fields parameter" do
    p = described_class.new({ "fields" => %w(title description) }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(return_fields: %w(title description)))
  end

  it "complains about invalid fields parameters" do
    p = described_class.new({ "fields" => %w(title waffle) }, @schema)

    expect(p.error).to eq("Some requested fields are not valid return fields: [\"waffle\"]")
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params(return_fields: %w[title]))
  end

  it "understands the debug parameter" do
    p = described_class.new({ "debug" => ["disable_best_bets,disable_popularity,,unknown_option"] }, @schema)

    expect(p.error).to eq(%{Unknown debug option "unknown_option"})
    expect(p).not_to be_valid
    expect(p.parsed_params).to match(expected_params(debug: { disable_best_bets: true, disable_popularity: true }))
  end

  it "merges values from repeated debug parameters" do
    p = described_class.new({ "debug" => ["disable_best_bets,explain", "disable_popularity"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(debug: { disable_best_bets: true, explain: true, disable_popularity: true }))
  end

  it "ignores empty options in the debug parameter" do
    p = described_class.new({ "debug" => [",,"] }, @schema)

    expect(p.error).to eq("")
    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(debug: {}))
  end

  it "understands explain in the debug parameter" do
    p = described_class.new({ "debug" => ["explain"] }, @schema)

    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(debug: { explain: true }))
  end

  it "understands disable synonyms in the debug parameter" do
    p = described_class.new({ "debug" => ["disable_synonyms"] }, @schema)

    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(debug: { disable_synonyms: true }))
  end

  it "understands the test variant parameter" do
    p = described_class.new({ "ab_tests" => ["min_should_match_length:A"] }, @schema)

    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(ab_tests: { min_should_match_length: 'A' }))
  end

  it "understands multiple test variant parameters" do
    p = described_class.new({ "ab_tests" => ["min_should_match_length:A,other_test_case:B"] }, @schema)

    expect(p).to be_valid
    expect(p.parsed_params).to match(expected_params(ab_tests: { min_should_match_length: 'A', other_test_case: 'B' }))
  end

  it "complains about invalid test variant where no variant type is provided" do
    p = described_class.new({ "ab_tests" => ["min_should_match_length"] }, @schema)

    expect(p).not_to be_valid
    expect(p.error).to eq("Invalid ab_tests, missing type \"min_should_match_length\"")
  end
end
