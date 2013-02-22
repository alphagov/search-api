require "test_helper"
require "elasticsearch_wrapper"
require "webmock"

class ElasticsearchWrapperAdvancedSearchTest < MiniTest::Unit::TestCase
  include Fixtures::DefaultMappings

  def setup
    @settings = {
      server: "example.com",
      port: 9200,
      index_name: "test-index"
    }
    @wrapper = ElasticsearchWrapper.new(@settings, default_mappings)
  end

  def test_pagination_params_are_required
    stub_empty_search

    assert_rejected_search("Pagination params are required.", {})
    assert @wrapper.advanced_search({'page' => '1', 'per_page' => '1'})
  end

  def test_pagination_params_are_converted_to_from_and_to_correctly
    stub_empty_search(:body => /\"from\":0,\"size\":10/)
    @wrapper.advanced_search({'page' => '1', 'per_page' => '10'})

    stub_empty_search(:body => /\"from\":6,\"size\":3/)
    @wrapper.advanced_search({'page' => '3', 'per_page' => '3'})
  end

  def test_keyword_param_is_converted_to_a_boosted_title_and_unboosted_general_query
    stub_empty_search(:body => /#{Regexp.escape("\"query\":"+
    "{\"bool\":{\"should\":["+
      "{\"text\":{\"title\":"+
        "{\"query\":\"happy fun time\",\"type\":\"phrase_prefix\",\"operator\":\"and\",\"analyzer\":\"query_default\",\"boost\":10,\"fuzziness\":0.5}"+
      "}},"+
      "{\"query_string\":"+
        "{\"query\":\"happy fun time\",\"default_operator\":\"and\",\"analyzer\":\"query_default\"}"+
      "}]}}")}/)
    @wrapper.advanced_search(default_params.merge('keywords' => 'happy fun time'))
  end

  def test_missing_keyword_param_means_a_match_all_query
    stub_empty_search(:body => /#{Regexp.escape("\"query\":{\"match_all\":{}}")}/)
    @wrapper.advanced_search(default_params)
  end

  def test_single_value_filter_param_is_turned_into_a_term_filter
    stub_empty_search(:body => /#{Regexp.escape("\"filter\":{\"term\":{\"section\":\"jones\"}}")}/)
    @wrapper.advanced_search(default_params.merge('section' => 'jones'))

    stub_empty_search(:body => /#{Regexp.escape("\"filter\":{\"term\":{\"section\":\"jones\"}}")}/)
    @wrapper.advanced_search(default_params.merge('section' => ['jones']))
  end

  def test_multiple_value_filter_param_is_turned_into_a_terms_filter
    stub_empty_search(:body => /#{Regexp.escape("\"filter\":{\"terms\":{\"section\":[\"jones\",\"richards\"]}}")}/)
    @wrapper.advanced_search(default_params.merge('section' => ['jones', 'richards']))
  end

  def test_filter_params_are_turned_into_anded_term_filters_on_that_property
    stub_empty_search(:body => /#{Regexp.escape("\"filter\":{\"and\":[{\"term\":{\"section\":\"jones\"}},{\"term\":{\"link\":\"richards\"}}]}")}/)
    @wrapper.advanced_search(default_params.merge('section' => ['jones'], 'link' => ['richards']))
  end

  def test_filter_params_on_a_boolean_mapping_property_are_convered_to_true_based_on_something_that_looks_truthy
    @wrapper.mappings['edition']['properties']['boolean_property'] = { "type" => "boolean", "index" => "analyzed" }
    stub_empty_search(:body => /#{Regexp.escape("\"filter\":{\"term\":{\"boolean_property\":true}}")}/)
    @wrapper.advanced_search(default_params.merge('boolean_property' => 'true'))
    @wrapper.advanced_search(default_params.merge('boolean_property' => '1'))
  end

  def test_filter_params_on_a_boolean_mapping_property_are_convered_to_false_based_on_something_that_looks_falsey
    @wrapper.mappings['edition']['properties']['boolean_property'] = { "type" => "boolean", "index" => "analyzed" }
    stub_empty_search(:body => /#{Regexp.escape("\"filter\":{\"term\":{\"boolean_property\":false}}")}/)
    @wrapper.advanced_search(default_params.merge('boolean_property' => 'false'))
    @wrapper.advanced_search(default_params.merge('boolean_property' => '0'))
  end

  def test_filter_params_on_a_boolean_mapping_property_are_rejected_if_they_dont_look_truthy_or_falsey
    @wrapper.mappings['edition']['properties']['boolean_property'] = { "type" => "boolean", "index" => "analyzed" }
    stub_empty_search

    assert_rejected_search('Invalid value "falsey" for boolean property "boolean_property"', default_params.merge('boolean_property' => 'falsey'))
    assert_rejected_search('Invalid value "truey" for boolean property "boolean_property"', default_params.merge('boolean_property' => 'truey'))
    assert_rejected_search('Invalid value "true facts" for boolean property "boolean_property"', default_params.merge('boolean_property' => 'true facts'))
    assert_rejected_search('Invalid value "101" for boolean property "boolean_property"', default_params.merge('boolean_property' => '101'))
    assert_rejected_search('Invalid value "cheese" for boolean property "boolean_property"', default_params.merge('boolean_property' => 'cheese'))
  end

  def test_filter_params_on_a_date_mapping_property_are_turned_into_a_range_filter_with_order_based_on_the_key_in_the_value
    @wrapper.mappings['edition']['properties']['date_property'] = { "type" => "date", "index" => "analyzed" }

    stub_empty_search(:body => /#{Regexp.escape("\"filter\":{\"range\":{\"date_property\":{\"to\":\"2013-02-02\"}}}")}/)
    @wrapper.advanced_search(default_params.merge('date_property' => {'before' => '2013-02-02'}))

    stub_empty_search(:body => /#{Regexp.escape("\"filter\":{\"range\":{\"date_property\":{\"from\":\"2013-02-02\"}}}")}/)
    @wrapper.advanced_search(default_params.merge('date_property' => {'after' => '2013-02-02'}))

    stub_empty_search(:body => /#{Regexp.escape("\"filter\":{\"range\":{\"date_property\":{\"from\":\"2013-02-02\",\"to\":\"2013-02-03\"}}}")}/)
    @wrapper.advanced_search(default_params.merge('date_property' => {'after' => '2013-02-02', 'before' => '2013-02-03'}))
  end

  def test_filter_params_on_a_date_mapping_property_without_a_before_or_after_key_in_the_value_are_rejected
    @wrapper.mappings['edition']['properties']['date_property'] = { "type" => "date", "index" => "analyzed" }
    stub_empty_search

    assert_rejected_search('Invalid value {} for date property "date_property"', default_params.merge('date_property' => {}))
    assert_rejected_search('Invalid value {"from"=>"2013-02-02"} for date property "date_property"', default_params.merge('date_property' => {'from' => '2013-02-02'}))
    assert_rejected_search('Invalid value "2013-02-02" for date property "date_property"', default_params.merge('date_property' => '2013-02-02'))
    assert_rejected_search('Invalid value {"to"=>"2013-02-02"} for date property "date_property"', default_params.merge('date_property' => {'to' => '2013-02-02'}))
    assert_rejected_search('Invalid value ["2013-02-02"] for date property "date_property"', default_params.merge('date_property' => ['2013-02-02']))
    assert_rejected_search('Invalid value {"between"=>"2013-02-02"} for date property "date_property"', default_params.merge('date_property' => {'between' => '2013-02-02'}))
    assert_rejected_search('Invalid value {"before"=>"2013-02-02", "up-to"=>"2013-02-02"} for date property "date_property"', default_params.merge('date_property' => {'before' => '2013-02-02', 'up-to' => '2013-02-02'}))
  end

  def test_filter_params_on_a_date_mapping_property_without_a_incorrectly_formatted_date_are_rejected
    @wrapper.mappings['edition']['properties']['date_property'] = { "type" => "date", "index" => "analyzed" }
    stub_empty_search

    assert_rejected_search('Invalid value {"before"=>"2 Feb 2013"} for date property "date_property"', default_params.merge('date_property' => {'before' => '2 Feb 2013'}))
    assert_rejected_search('Invalid value {"before"=>"2/2/2013"} for date property "date_property"', default_params.merge('date_property' => {'before' => '2/2/2013'}))
    assert_rejected_search('Invalid value {"before"=>"2013/2/2"} for date property "date_property"', default_params.merge('date_property' => {'before' => '2013/2/2'}))
    assert_rejected_search('Invalid value {"before"=>"2013-2-2"} for date property "date_property"', default_params.merge('date_property' => {'before' => '2013-2-2'}))
  end

  def test_filter_params_that_are_not_index_properties_are_not_allowed
    assert_rejected_search('Querying unknown properties ["brian", "keith"]', default_params.merge('brian' => 'jones', 'keith' => 'richards'))
  end

  def test_order_params_are_turned_into_a_sort_query
    stub_empty_search(:body => /#{Regexp.escape("\"sort\":[{\"title\":\"asc\"}]")}/)
    @wrapper.advanced_search(default_params.merge('order' => {'title' => 'asc'}))
  end

  def test_order_params_on_properties_not_in_the_mappings_are_not_allowed
    assert_rejected_search('Sorting on unknown property ["brian"]', default_params.merge('order' => {'brian' => 'asc'}))
  end

  def test_returns_the_total_and_the_hits
    stub_empty_search()
    expected_result = {total: 0, results: []}
    assert_equal expected_result, @wrapper.advanced_search(default_params)
  end

  def test_returns_the_hits_converted_into_documents
    Document.expects(:from_hash).with({"woo" => "hoo"}, default_mappings).returns :woo_hoo
    stub_request(:get, "http://example.com:9200/test-index/_search")
      .to_return(:status => 200, :body => "{\"hits\": {\"total\": 10, \"hits\": [{\"_source\": {\"woo\": \"hoo\"}}]}}", :headers => {})
    expected_result = {total: 10, results: [:woo_hoo]}
    assert_equal expected_result, @wrapper.advanced_search(default_params)
  end

  def default_params
    {'page' => '1', 'per_page' => '1'}
  end

  def stub_empty_search(with_args = {})
    r = stub_request(:get, "http://example.com:9200/test-index/_search")
    r.with(with_args) unless with_args.empty?
    r.to_return(:status => 200, :body => "{\"hits\": {\"total\": 0, \"hits\": []}}", :headers => {})
  end

  def assert_rejected_search(expected_error, search_args)
    e = assert_raises(RuntimeError) do
      @wrapper.advanced_search(search_args)
    end
    assert_equal expected_error, e.message
  end
end
