require "test_helper"
require "unified_searcher"
require "document"

class UnifiedSearchPresenterTest < ShouldaUnitTestCase

  DOCS = [{
    _metadata: {
      "_index" => "government-2014-03-19t14:35:28z-a05cfc73-933a-41c7-adc0-309a715baf09",
      _type: "edition",
      _id: "/government/publications/staffordshire-cheese",
      "_score" => 3.0514863,
    },
    "description" => "Staffordshire Cheese Product of Designated Origin (PDO) and Staffordshire Organic Cheese.",
    "title" => "Staffordshire Cheese",
    "link" => "/government/publications/staffordshire-cheese",
  }, {
    _metadata: {
      "_index" => "mainstream-2014-03-19t14:35:28z-6472f975-dc38-49a5-98eb-c498e619650c",
      _type: "edition",
      _id: "/duty-relief-for-imports-and-exports",
      "_score" => 0.49672604,
    },
    "description" => "Schemes that offer reduced or zero rate duty and VAT for imports and exports",
    "title" => "Duty relief for imports and exports",
    "link" => "/duty-relief-for-imports-and-exports",
  }, {
    _metadata: {
      "_index" => "detailed-2014-03-19t14:35:27z-27e2831f-bd14-47d8-9c7a-3017e213efe3",
      _type: "edition",
      _id: "/dairy-farming-and-schemes",
      "_score" => 0.34655035,
    },
    "title" => "Dairy farming and schemes",
    "link" => "/dairy-farming-and-schemes",
    "topics" => ["farming"],
  }]

  INDEX_NAMES = %w(mainstream government detailed)

  context "no results" do
    setup do
      results = {
        results: [],
        total: 0,
        start: 0,
      }
      @output = UnifiedSearchPresenter.new(results, INDEX_NAMES).present
    end

    should "present empty list of results" do
      assert_equal [], @output[:results]
    end

    should "have total of 0" do
      assert_equal 0, @output[:total]
    end
  end

  context "results with no registries" do
    setup do
      results = {
        results: Marshal.load(Marshal.dump(DOCS)),
        total: 3,
        start: 0,
      }
      @output = UnifiedSearchPresenter.new(results, INDEX_NAMES).present
    end

    should "have correct total" do
      assert_equal 3, @output[:total]
    end

    should "have correct number of results" do
      assert_equal 3, @output[:results].length
    end

    should "have short index names" do
      @output[:results].each do |result|
        assert_contains INDEX_NAMES, result[:index]
      end
    end

    should "have the score in es_score" do
      @output[:results].zip(DOCS).each do |result, doc|
        assert_does_not_contain "_score", result.keys
        assert result[:es_score] != nil
        assert_equal doc[:_metadata]["_score"], result[:es_score]
      end
    end

    should "have only the fields returned from search engine" do
      @output[:results].zip(DOCS).each do |result, doc|
        doc_fields = result.keys - [:_type, :_id]
        returned_fields = result.keys - [:esscore, :_type, :_id]
        assert_equal doc_fields, returned_fields
      end
    end
  end

  context "results with a registry" do
    setup do
      results = {
        results: Marshal.load(Marshal.dump(DOCS)),
        total: 3,
        start: 0,
      }
      farming_topic_document = Document.new(
        %w(link title),
        link: "/government/topics/farming",
        title: "Farming"
      )
      topic_registry = stub("topic registry")
      topic_registry.expects(:[])
        .with("farming")
        .returns(farming_topic_document)

      @output = UnifiedSearchPresenter.new(
        results,
        INDEX_NAMES,
        topic_registry: topic_registry
      ).present
    end

    should "have correct total" do
      assert_equal 3, @output[:total]
    end

    should "have correct number of results" do
      assert_equal 3, @output[:results].length
    end

    should "have short index names" do
      @output[:results].each do |result|
        assert_contains INDEX_NAMES, result[:index]
      end
    end

    should "have the score in es_score" do
      @output[:results].zip(DOCS).each do |result, doc|
        assert_does_not_contain "_score", result.keys
        assert result[:es_score] != nil
        assert_equal doc[:_metadata]["_score"], result[:es_score]
      end
    end

    should "have only the fields returned from search engine" do
      @output[:results].zip(DOCS).each do |result, doc|
        doc_fields = result.keys - [:_type, :_id]
        returned_fields = result.keys - [:esscore, :_type, :_id]
        assert_equal doc_fields, returned_fields
      end
    end

    should "have the expanded topic" do
      result = @output[:results][2]
      assert_equal([{
        "link" => "/government/topics/farming",
        "title" => "Farming",
        "slug" => "farming",
      }], result["topics"])
    end
  end

end
