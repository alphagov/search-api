require "integration_test_helper"

class ContentEndpointsTest < IntegrationTest
  def setup
    stub_elasticsearch_settings
  end

  def test_content_document_not_found
    result = { "hits" => { "hits" => [] } }

    stub_request(:get, "http://localhost:9200/mainstream_test,detailed_test,government_test/_search").
      to_return(status: 200, body: JSON.dump(result))

    get "/content?link=/a-document/that-does-not-exist"

    assert last_response.not_found?
  end

  def test_that_getting_a_document_returns_the_document
    result = {
       "hits"=>
        {"hits"=>
          [{"_index"=>
             "mainstream-2015-07-14t12:15:23z-00000000-0000-0000-0000-000000000000",
            "_type"=>"edition",
            "_id"=>"/vehicle-tax",
            "_score"=>1.0,
            "_source"=> 'THE_RAW_SOURCE' }]}}

    stub_request(:get, "http://localhost:9200/mainstream_test,detailed_test,government_test/_search").
      to_return(status: 200, body: JSON.dump(result))

    get "/content?link=a-document/in-search"

    assert last_response.ok?
    assert_equal 'THE_RAW_SOURCE', parsed_response['raw_source']
  end

  def test_deleting_a_document
    result = {
       "hits"=>
        {"hits"=>
          [{"_index"=>
             "mainstream_test",
            "_type"=>"edition",
            "_id"=>"/vehicle-tax",
            "_score"=>1.0,
            "_source"=> 'THE_RAW_SOURCE' }]}}

    stub_request(:get, "http://localhost:9200/mainstream_test,detailed_test,government_test/_search").
      to_return(status: 200, body: JSON.dump(result))

    stub_request(:delete, "http://localhost:9200/mainstream_test/edition/%2Fvehicle-tax").
      to_return(status: 200, body: "{}")

    delete "/content?link=a-document/in-search"

    assert_equal 204, last_response.status
  end

  def test_deleting_a_document_that_doesnt_exist
    result = { "hits" => { "hits" => [] } }

    stub_request(:get, "http://localhost:9200/mainstream_test,detailed_test,government_test/_search").
      to_return(status: 200, body: JSON.dump(result))

    delete "/content?link=a-document/in-search"

    assert last_response.not_found?
  end

  def test_deleting_a_document_from_locked_index
    result = {
       "hits"=>
        {"hits"=>
          [{"_index"=>
             "mainstream_test",
            "_type"=>"edition",
            "_id"=>"/vehicle-tax",
            "_score"=>1.0,
            "_source"=> 'THE_RAW_SOURCE' }]}}

    stub_request(:get, "http://localhost:9200/mainstream_test,detailed_test,government_test/_search").
      to_return(status: 200, body: JSON.dump(result))

    Elasticsearch::Index.any_instance.expects(:delete).raises(Elasticsearch::IndexLocked)

    delete "/content?link=a-document/in-search"

    assert_equal 423, last_response.status
  end
end
