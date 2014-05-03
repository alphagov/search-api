require "test_helper"
require "elasticsearch/search_server"

class SearchServerTest < MiniTest::Unit::TestCase
  EMPTY_SCHEMA = { "mappings" => { "default" => nil } }

  def test_returns_an_index
    search_server = Elasticsearch::SearchServer.new("http://l", EMPTY_SCHEMA, ["a", "b"], ["a"])
    index = search_server.index("a")
    assert index.is_a?(Elasticsearch::Index)
    assert_equal "a", index.index_name
  end

  def test_raises_an_error_for_unknown_index
    search_server = Elasticsearch::SearchServer.new("http://l", EMPTY_SCHEMA, ["a", "b"], ["a"])
    assert_raises Elasticsearch::NoSuchIndex do
      search_server.index("z")
    end
  end

  def test_can_get_multi_index
    search_server = Elasticsearch::SearchServer.new("http://l", EMPTY_SCHEMA, ["a", "b"], ["a"])
    index = search_server.index("a,b")
    assert index.is_a?(Elasticsearch::Index)
    assert_equal "a,b", index.index_name
  end

  def test_raises_an_error_for_unknown_index_in_multi_index
    search_server = Elasticsearch::SearchServer.new("http://l", EMPTY_SCHEMA, ["a", "b"], ["a"])
    assert_raises Elasticsearch::NoSuchIndex do
      search_server.index("a,z")
    end
  end

  def test_promoted_results_generated_from_schema_settings
    schema = EMPTY_SCHEMA.dup
    schema["promoted_results"] = [{
      "terms" => "job",
      "link" => "/jobsearch"
      }]
    server = Elasticsearch::SearchServer.new(
      "http://localhost:9200/",
      schema,
      ["mainstream", "custom"],
      ["mainstream", "custom"],
    )
    promoted_results = server.promoted_results

    assert_equal [["job"]], promoted_results.map {|r| r.terms}
    assert_equal ["/jobsearch"], promoted_results.map {|r| r.link}
  end

  def test_promoted_results_passed_to_index_group
    server = Elasticsearch::SearchServer.new(
      "http://localhost:9200/",
      EMPTY_SCHEMA,
      ["mainstream", "custom"],
      ["mainstream", "custom"],
    )
    promoted_results = stub("promoted results")
    server.stubs(:promoted_results).returns(promoted_results)
    Elasticsearch::IndexGroup.expects(:new).with(anything,anything,anything,anything,promoted_results)
    server.index_group("mainstream")
  end

end
