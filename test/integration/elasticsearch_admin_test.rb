require "integration_test_helper"
require "app"
require "rest-client"
require "elasticsearch_admin_wrapper"

class ElasticsearchAdminTest < IntegrationTest

  # Test index and mapping creation works properly

  def setup
    use_elasticsearch_for_primary_search
    disable_secondary_search
    WebMock.disable_net_connect!(allow: "localhost:9200")
    delete_elasticsearch_index

    @wrapper = ElasticsearchAdminWrapper.new(
      settings.backends[:primary],
      settings.elasticsearch_schema
    )
  end

  def index_status
    JSON.parse(RestClient.get("http://localhost:9200/_status"))
  end

  def assert_index_exists
    assert index_status["indices"]["rummager_test"]
  end

  def assert_index_does_not_exist
    assert_nil index_status["indices"]["rummager_test"]
  end

  def assert_type_exists(type)
    mapping = JSON.parse(
      RestClient.get "http://localhost:9200/rummager_test/_mapping"
    )
    assert mapping["rummager_test"][type]
  end

  def assert_type_does_not_exist(type)
    begin
      response = RestClient.get("http://localhost:9200/rummager_test/_mapping")
    rescue RestClient::ResourceNotFound
      # If the mapping isn't defined, the type can't exist
      return
    end

    mapping = JSON.parse(response)
    assert_false mapping["rummager_test"][type]
  end

  def test_should_create_an_index
    assert_equal :created, @wrapper.ensure_index
    assert_index_exists
  end

  def test_should_return_symbol_if_index_exists
    assert_equal :created, @wrapper.ensure_index
    assert_equal :updated, @wrapper.ensure_index
    assert_index_exists
  end

  def test_should_delete_index
    @wrapper.ensure_index
    assert_index_exists
    assert_equal :deleted, @wrapper.delete_index
    assert_index_does_not_exist
  end

  def test_should_return_symbol_if_index_does_not_exist
    assert_equal :absent, @wrapper.delete_index
    assert_index_does_not_exist
  end

  def test_should_recreate_index
    assert_equal :created, @wrapper.ensure_index
    assert_index_exists

    @wrapper.put_mappings
    assert_type_exists "edition"

    @wrapper.ensure_index!
    assert_index_exists
    assert_type_does_not_exist "edition"
  end

  def test_should_create_mappings
    assert_equal :created, @wrapper.ensure_index!
    assert_index_exists

    assert_type_does_not_exist "edition"

    @wrapper.put_mappings
    assert_type_exists "edition"
  end
end
