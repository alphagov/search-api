require "integration_test_helper"
require "app"
require "rest-client"
require "elasticsearch_admin_wrapper"

class ElasticsearchAdminTest < IntegrationTest

  FLAKY_MESSAGE = "The index tests are far too unpredictable on Jenkins."

  # Test index and mapping creation works properly

  def setup
    WebMock.disable_net_connect!(allow: "localhost:9200")
    delete_elasticsearch_index
    @index_name = "rummager_test"
  end

  def test_ensure_index_should_create_an_index
    skip(FLAKY_MESSAGE)
    assert_index_does_not_exist
    assert_equal :created, wrapper_for("rummager_test").ensure_index
    assert_index_exists
  end

  def test_ensure_index_should_indicate_updated_if_index_exists
    skip(FLAKY_MESSAGE)
    wrapper = wrapper_for("rummager_test")
    wrapper.ensure_index
    assert_equal :updated, wrapper.ensure_index
  end

  def test_delete_index_should_delete_index
    skip(FLAKY_MESSAGE)
    wrapper = wrapper_for("rummager_test")
    wrapper.ensure_index
    assert_equal :deleted, wrapper.delete_index
    assert_index_does_not_exist
  end

  def test_delete_index_should_indicate_absent_if_index_does_not_exist
    skip(FLAKY_MESSAGE)
    assert_index_does_not_exist
    assert_equal :absent, wrapper_for("rummager_test").delete_index
  end

  def test_put_mappings_should_create_mappings_using_default_settings
    skip(FLAKY_MESSAGE)
    wrapper = wrapper_for("rummager_test")
    wrapper.ensure_index!
    assert_type_does_not_exist "edition"

    wrapper.put_mappings

    expected_properties = {
      "title" => {"type" => "string"}
    }
    assert_equal expected_properties, get_mapping("rummager_test")['edition']['properties']
  end

  def test_ensure_index_bang_should_recreate_index_and_remove_any_type_definitions
    skip(FLAKY_MESSAGE)
    wrapper = wrapper_for("rummager_test")
    wrapper.ensure_index
    wrapper.put_mappings
    assert_type_exists "edition"

    wrapper.ensure_index!
    assert_index_exists
    assert_type_does_not_exist "edition"
  end

  def test_put_mappings_should_load_per_index_mappings_if_defined
    skip(FLAKY_MESSAGE)
    @government_wrapper = wrapper_for("government")
    @government_wrapper.delete_index
    @government_wrapper.ensure_index

    @government_wrapper.put_mappings

    expected_properties = {
      "topics" => {"type" => "string"},
      "title" => {"type" => "string"}
    }
    assert_equal expected_properties, get_mapping("government")['edition']['properties']
  end

private

  def index_status
    MultiJson.decode(RestClient.get("http://localhost:9200/_status"))
  end

  def delete_elasticsearch_index
    begin
      RestClient.delete "http://localhost:9200/#{@index_name}"
    rescue RestClient::Exception => exception
      raise unless exception.http_code == 404
    end
  end

  def assert_index_exists
    assert index_status["indices"][@index_name]
  end

  def assert_index_does_not_exist
    assert_nil index_status["indices"][@index_name]
  end

  def get_mapping(index_name)
    MultiJson.decode(RestClient.get "http://localhost:9200/#{index_name}/_mapping")[index_name]
  rescue RestClient::ResourceNotFound
    nil
  end

  def assert_type_exists(type)
    assert get_mapping(@index_name)[type]
  end

  def assert_type_does_not_exist(type)
    mapping = get_mapping(@index_name)
    assert mapping.nil? || mapping[type].nil?
  end

end
