require 'spec_helper'

RSpec.describe SearchIndices::Index, 'Advanced Search' do
  include Fixtures::DefaultMappings

  before do
    base_uri = "http://example.com:9200"
    search_config = SearchConfig.default_instance
    @wrapper = described_class.new(base_uri, "government_test", "government_test", default_mappings, search_config)
  end

  it "pagination params are required" do
    stub_empty_search

    expect_rejected_search("Pagination params are required.", {})
    expect(@wrapper.advanced_search({ 'page' => '1', 'per_page' => '1' })).to be_truthy
  end

  it "pagination params are converted to from and to correctly" do
    stub_empty_search(body: /\"from\":0,\"size\":10/)
    @wrapper.advanced_search({ 'page' => '1', 'per_page' => '10' })

    stub_empty_search(body: /\"from\":6,\"size\":3/)
    @wrapper.advanced_search({ 'page' => '3', 'per_page' => '3' })
  end

  it "keyword param is converted to a boosted title and unboosted general query" do
    stub_empty_search(body: {
      "from" => 0,
      "size" => 1,
      "post_filter" => {
        "bool" => {
          "must" => [{ "bool" => { "must_not" => { "term" => { "is_withdrawn" => true } } } }]
        }
      },
      "query" => {
        "bool" => {
          "must" => {
            "function_score" => {
              "query" => {
                "bool" => {
                  "should" => [
                    {
                      "query_string" => {
                        "query" => "happy fun time",
                        "fields" => ["title^3"],
                        "default_operator" => "and",
                        "analyzer" => "default"
                      }
                    },
                    {
                      "query_string" =>
                      {
                        "query" => "happy fun time",
                        "analyzer" => "with_search_synonyms"
                      }
                    }
                  ]
                }
              },
              "functions" => [
                {
                  "filter" => {
                    "term" => {
                      "search_format_types" => "edition"
                    }
                  },
                  "script_score" => {
                    "script" => {
                      "lang" => "painless",
                      "inline" => "((0.15 / ((3.1*Math.pow(10,-11)) * Math.abs(params.now - doc['public_timestamp'].date.getMillis()) + 0.05)) + 0.5)",
                      "params" => { "now" => (Time.now.to_i / 60) * 60000 }
                    },
                  }
                }
              ]
            }
          },
        }
      }
    })
    @wrapper.advanced_search(default_params.merge('keywords' => 'happy fun time'))
  end

  it "missing keyword param means a match all query" do
    stub_empty_search(body: /#{Regexp.escape("\"must\":{\"match_all\":{}}")}/)
    @wrapper.advanced_search(default_params)
  end

  it "single value filter param is turned into a term filter" do
    stub_empty_search(body: /#{Regexp.escape("\"term\":{\"mainstream_browse_pages\":\"jones\"}")}/)
    @wrapper.advanced_search(default_params.merge('mainstream_browse_pages' => 'jones'))

    stub_empty_search(body: /#{Regexp.escape("\"term\":{\"mainstream_browse_pages\":\"jones\"}")}/)
    @wrapper.advanced_search(default_params.merge('mainstream_browse_pages' => ['jones']))
  end

  it "multiple value filter param is turned into a terms filter" do
    stub_empty_search(body: /#{Regexp.escape("\"terms\":{\"mainstream_browse_pages\":[\"jones\",\"richards\"]}")}/)
    @wrapper.advanced_search(default_params.merge('mainstream_browse_pages' => %w(jones richards)))
  end

  it "filter params are turned into anded term filters on that property" do
    stub_empty_search(body: /#{Regexp.escape("[{\"term\":{\"mainstream_browse_pages\":\"jones\"}},{\"term\":{\"link\":\"richards\"}},")}/)
    @wrapper.advanced_search(default_params.merge('mainstream_browse_pages' => ['jones'], 'link' => ['richards']))
  end

  it "filter params on a boolean mapping property are convered to true based on something that looks truthy" do
    @wrapper.mappings['generic-document']['properties']['boolean_property'] = { "type" => "boolean", "index" => true }
    stub_empty_search(body: /#{Regexp.escape("{\"term\":{\"boolean_property\":true}")}/)
    @wrapper.advanced_search(default_params.merge('boolean_property' => 'true'))
    @wrapper.advanced_search(default_params.merge('boolean_property' => '1'))
  end

  it "filter params on a boolean mapping property are convered to false based on something that looks falsey" do
    @wrapper.mappings['generic-document']['properties']['boolean_property'] = { "type" => "boolean", "index" => true }
    stub_empty_search(body: /#{Regexp.escape("\"term\":{\"boolean_property\":false}")}/)
    @wrapper.advanced_search(default_params.merge('boolean_property' => 'false'))
    @wrapper.advanced_search(default_params.merge('boolean_property' => '0'))
  end

  it "filter params on a boolean mapping property are rejected if they dont look truthy or falsey" do
    @wrapper.mappings['generic-document']['properties']['boolean_property'] = { "type" => "boolean", "index" => true }
    stub_empty_search

    expect_rejected_search('Invalid value "falsey" for boolean property "boolean_property"', default_params.merge('boolean_property' => 'falsey'))
    expect_rejected_search('Invalid value "truey" for boolean property "boolean_property"', default_params.merge('boolean_property' => 'truey'))
    expect_rejected_search('Invalid value "true facts" for boolean property "boolean_property"', default_params.merge('boolean_property' => 'true facts'))
    expect_rejected_search('Invalid value "101" for boolean property "boolean_property"', default_params.merge('boolean_property' => '101'))
    expect_rejected_search('Invalid value "cheese" for boolean property "boolean_property"', default_params.merge('boolean_property' => 'cheese'))
  end

  it "filter params on a date mapping property are turned into a range filter with order based on the key in the value" do
    @wrapper.mappings['generic-document']['properties']['date_property'] = { "type" => "date", "index" => true }

    stub_empty_search(body: /#{Regexp.escape("\"range\":{\"date_property\":{\"to\":\"2013-02-02\"}}")}/)
    @wrapper.advanced_search(default_params.merge('date_property' => { 'to' => '2013-02-02' }))

    stub_empty_search(body: /#{Regexp.escape("\"range\":{\"date_property\":{\"from\":\"2013-02-02\"}}")}/)
    @wrapper.advanced_search(default_params.merge('date_property' => { 'from' => '2013-02-02' }))

    stub_empty_search(body: /#{Regexp.escape("\"range\":{\"date_property\":{\"from\":\"2013-02-02\",\"to\":\"2013-02-03\"}}")}/)
    @wrapper.advanced_search(default_params.merge('date_property' => { 'from' => '2013-02-02', 'to' => '2013-02-03' }))

    # Deprecated date range options
    stub_empty_search(body: /#{Regexp.escape("\"range\":{\"date_property\":{\"to\":\"2013-02-02\"}}")}/)
    @wrapper.advanced_search(default_params.merge('date_property' => { 'before' => '2013-02-02' }))

    stub_empty_search(body: /#{Regexp.escape("\"range\":{\"date_property\":{\"from\":\"2013-02-02\"}}")}/)
    @wrapper.advanced_search(default_params.merge('date_property' => { 'after' => '2013-02-02' }))
  end

  it "filter params on a date mapping property without a before or after key in the value are rejected" do
    @wrapper.mappings['generic-document']['properties']['date_property'] = { "type" => "date", "index" => true }
    stub_empty_search

    expect_rejected_search('Invalid value {} for date property "date_property"', default_params.merge('date_property' => {}))
    expect_rejected_search('Invalid value "2013-02-02" for date property "date_property"', default_params.merge('date_property' => '2013-02-02'))
    expect_rejected_search('Invalid value ["2013-02-02"] for date property "date_property"', default_params.merge('date_property' => ['2013-02-02']))
    expect_rejected_search('Invalid value {"between"=>"2013-02-02"} for date property "date_property"', default_params.merge('date_property' => { 'between' => '2013-02-02' }))
    expect_rejected_search('Invalid value {"before"=>"2013-02-02", "up-to"=>"2013-02-02"} for date property "date_property"', default_params.merge('date_property' => { 'before' => '2013-02-02', 'up-to' => '2013-02-02' }))
  end

  it "filter params on a date mapping property without a incorrectly formatted date are rejected" do
    @wrapper.mappings['generic-document']['properties']['date_property'] = { "type" => "date", "index" => true }
    stub_empty_search

    expect_rejected_search('Invalid value {"before"=>"2 Feb 2013"} for date property "date_property"', default_params.merge('date_property' => { 'before' => '2 Feb 2013' }))
    expect_rejected_search('Invalid value {"before"=>"2/2/2013"} for date property "date_property"', default_params.merge('date_property' => { 'before' => '2/2/2013' }))
    expect_rejected_search('Invalid value {"before"=>"2013/2/2"} for date property "date_property"', default_params.merge('date_property' => { 'before' => '2013/2/2' }))
    expect_rejected_search('Invalid value {"before"=>"2013-2-2"} for date property "date_property"', default_params.merge('date_property' => { 'before' => '2013-2-2' }))
  end

  it "filter params that are not index properties are not allowed" do
    expect_rejected_search('Querying unknown properties ["brian", "keith"]', default_params.merge('brian' => 'jones', 'keith' => 'richards'))
  end

  it "order params are turned into a sort query" do
    stub_empty_search(body: /#{Regexp.escape("\"sort\":[{\"title\":\"asc\"}]")}/)
    @wrapper.advanced_search(default_params.merge('order' => { 'title' => 'asc' }))
  end

  it "order params on properties not in the mappings are not allowed" do
    expect_rejected_search('Sorting on unknown property ["brian"]', default_params.merge('order' => { 'brian' => 'asc' }))
  end

  it "returns the total and the hits" do
    stub_empty_search
    result_set = @wrapper.advanced_search(default_params)
    expect(result_set.total).to eq(0)
    expect(result_set.results).to eq([])
  end

  it "returns the hits converted into documents" do
    stub_request(:get, "http://example.com:9200/government_test/_search")
      .to_return(
        status: 200,
        body: "{\"hits\": {\"total\": 10, \"hits\": [{\"_source\": {\"indexable_content\": \"some_content\", \"document_type\": \"edition\"}, \"_type\": \"generic-document\"}]}}",
        headers: { "Content-Type" => "application/json" }
      )
    result_set = @wrapper.advanced_search(default_params)
    expect(result_set.total).to eq(10)
    expect(result_set.results.size).to eq(1)
    expect(result_set.results.first.get("indexable_content")).to eq("some_content")
  end

  def default_params
    { 'page' => '1', 'per_page' => '1' }
  end

  def stub_empty_search(with_args = {})
    r = stub_request(:get, "http://example.com:9200/government_test/_search")
    r.with(with_args) unless with_args.empty?
    r.to_return(
      status: 200,
      body: "{\"hits\": {\"total\": 0, \"hits\": []}}",
      headers: { "Content-Type" => "application/json" }
    )
  end

  def expect_rejected_search(expected_error, search_args)
    expect { @wrapper.advanced_search(search_args) }.to raise_error(expected_error)
  end
end
