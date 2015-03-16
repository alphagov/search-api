require "test_helper"
require "unified_searcher"
require "document"
require "search_parameter_parser"

class UnifiedSearchPresenterTest < ShouldaUnitTestCase

  def sample_docs
    [{
      "_index" => "government-2014-03-19t14:35:28z-a05cfc73-933a-41c7-adc0-309a715baf09",
      _type: "edition",
      _id: "/government/publications/staffordshire-cheese",
      "_score" => 3.0514863,
      "fields" => {
        "description" => "Staffordshire Cheese Product of Designated Origin (PDO) and Staffordshire Organic Cheese.",
        "title" => "Staffordshire Cheese",
        "link" => "/government/publications/staffordshire-cheese",
      },
    }, {
      "_index" => "mainstream-2014-03-19t14:35:28z-6472f975-dc38-49a5-98eb-c498e619650c",
      _type: "edition",
      _id: "/duty-relief-for-imports-and-exports",
      "_score" => 0.49672604,
      "fields" => {
        "description" => "Schemes that offer reduced or zero rate duty and VAT for imports and exports",
        "title" => "Duty relief for imports and exports",
        "link" => "/duty-relief-for-imports-and-exports",
      },
    }, {
      "_index" => "detailed-2014-03-19t14:35:27z-27e2831f-bd14-47d8-9c7a-3017e213efe3",
      _type: "edition",
      _id: "/dairy-farming-and-schemes",
      "_score" => 0.34655035,
      "fields" => {
        "title" => "Dairy farming and schemes",
        "link" => "/dairy-farming-and-schemes",
        "topics" => ["farming"],
      },
    }]
  end

  def sample_es_response(extra = {})
    {
      "hits" => {
        "hits" => sample_docs,
        "total" => 3,
      }
    }.merge(extra)
  end

  def sample_facet_data
    {
      "organisations" => {
        "terms" => [
          {"term" => "hm-magic", "count" => 7},
          {"term" => "hmrc", "count" => 5},
        ],
        "missing" => 8,
      }
    }
  end

  def sample_facet_data_with_topics
    {
      "organisations" => {
        "terms" => [
          {"term" => "hm-magic", "count" => 7},
          {"term" => "hmrc", "count" => 5},
        ],
        "missing" => 8,
      },
      "topics" => {
        "terms" => [
          {"term" => "farming", "count" => 4},
          {"term" => "unknown_topic", "count" => 5},
        ],
        "missing" => 3,
      },
    }
  end

  def sample_org_registry
    magic_org_document = Document.new(
      %w(link title),
      link: "/government/departments/hm-magic",
      title: "Ministry of Magic"
    )
    hmrc_org_document = Document.new(
      %w(link title),
      link: "/government/departments/hmrc",
      title: "HMRC"
    )
    org_registry = stub("org registry")
    org_registry.expects(:[])
      .with("hm-magic")
      .returns(magic_org_document)
    org_registry.expects(:[])
      .with("hmrc")
      .returns(hmrc_org_document)
    org_registry
  end

  def facet_response_magic
    {
      value: {
        "link"=>"/government/departments/hm-magic",
        "title"=>"Ministry of Magic",
        "slug"=>"hm-magic",
      },
      documents: 7,
    }
  end

  def facet_response_hmrc
    {
      value: {
        "link"=>"/government/departments/hmrc",
        "title"=>"HMRC",
        "slug"=>"hmrc",
      },
      documents: 5,
    }
  end

  def facet_params(requested, options={})
    {
      requested: requested,
      order: SearchParameterParser::DEFAULT_FACET_SORT,
    }.merge(options)
  end

  INDEX_NAMES = %w(mainstream government detailed)

  def search_presenter(options)
    org_registry = options[:org_registry]
    UnifiedSearchPresenter.new(
      sample_es_response(options.fetch(:es_response, {})),
      options.fetch(:start, 0),
      INDEX_NAMES,
      options.fetch(:filters, []),
      options.fetch(:facets, {}),
      org_registry.nil? ? {} : {organisation_registry: org_registry},
      org_registry.nil? ? {} : {organisations: org_registry},
      options.fetch(:suggestions, []),
      options.fetch(:facet_examples, {}),
      options.fetch(:schema, nil)
    )
  end

  context "no results" do
    setup do
      results = {
        "hits" => {
          "hits" => [],
          "total" => 0
        }
      }
      @output = UnifiedSearchPresenter.new(results, 0, INDEX_NAMES).present
    end

    should "present empty list of results" do
      assert_equal [], @output[:results]
    end

    should "have total of 0" do
      assert_equal 0, @output[:total]
    end

    should "have no facets" do
      assert_equal({}, @output[:facets])
    end
  end

  context "results with no registries" do
    setup do
      @output = UnifiedSearchPresenter.new(sample_es_response, 0, INDEX_NAMES).present
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
      @output[:results].zip(sample_docs).each do |result, doc|
        assert_does_not_contain "_score", result.keys
        assert result[:es_score] != nil
        assert_equal doc["_score"], result[:es_score]
      end
    end

    should "have only the fields returned from search engine" do
      @output[:results].zip(sample_docs).each do |result, doc|
        doc_fields = result.keys - [:_type, :_id]
        returned_fields = result.keys - [:esscore, :_type, :_id]
        assert_equal doc_fields, returned_fields
      end
    end
  end

  context "results with no fields" do
    setup do
      @empty_result = sample_docs.first.tap {|doc|
        doc['fields'] = nil
      }
      response = sample_es_response.tap {|response|
        response['hits']['hits'] = [ @empty_result ]
      }

      @output = UnifiedSearchPresenter.new(response, 0, INDEX_NAMES).present
    end

    should 'return only basic metadata of fields' do
      expected_keys = [:index, :es_score, :_id, :document_type]

      assert_equal expected_keys, @output[:results].first.keys
    end
  end

  context "results with a registry" do
    setup do
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
        sample_es_response,
        0,
        INDEX_NAMES,
        [],
        {},
        {topic_registry: topic_registry},
        {topics: topic_registry},
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
      @output[:results].zip(sample_docs).each do |result, doc|
        assert_does_not_contain "_score", result.keys
        assert result[:es_score] != nil
        assert_equal doc["_score"], result[:es_score]
      end
    end

    should "have only the fields returned from search engine" do
      @output[:results].zip(sample_docs).each do |result, doc|
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

  context "results with facets" do
    setup do
      @output = UnifiedSearchPresenter.new(
        sample_es_response("facets" => sample_facet_data),
        0,
        INDEX_NAMES,
        [],
        {"organisations" => facet_params(1)},
      ).present
    end

    should "have facets" do
      assert_contains @output.keys, :facets
    end

    should "have correct number of facets" do
      assert_equal 1, @output[:facets].length
    end

    should "have correct number of facet values" do
      assert_equal 1, @output[:facets]["organisations"][:options].length
    end

    should "have correct top facet value value" do
      assert_equal({
        :value=>{"slug"=>"hm-magic"},
        :documents=>7,
      }, @output[:facets]["organisations"][:options][0])
    end

    should "have correct number of documents with no value" do
      assert_equal(8, @output[:facets]["organisations"][:documents_with_no_value])
    end

    should "have correct total number of options" do
      assert_equal(2, @output[:facets]["organisations"][:total_options])
    end

    should "have correct number of missing options" do
      assert_equal(1, @output[:facets]["organisations"][:missing_options])
    end
  end

  context "results with facets and a filter applied" do
    setup do
      @output = UnifiedSearchPresenter.new(
        sample_es_response("facets" => sample_facet_data),
        0,
        INDEX_NAMES,
        [text_filter("organisations", ["hmrc"])],
        {"organisations" => facet_params(2)},
      ).present
    end

    should "have facets" do
      assert_contains @output.keys, :facets
    end

    should "have correct number of facets" do
      assert_equal 1, @output[:facets].length
    end

    should "have correct number of facet values" do
      assert_equal 2, @output[:facets]["organisations"][:options].length
    end

    should "have selected facet first" do
      assert_equal({
        :value => {"slug" => "hmrc"},
        :documents => 5,
      }, @output[:facets]["organisations"][:options][0])
    end

    should "have unapplied facet value second" do
      assert_equal({
        :value => {"slug" => "hm-magic"},
        :documents => 7,
      }, @output[:facets]["organisations"][:options][1])
    end

    should "have correct number of documents with no value" do
      assert_equal(8, @output[:facets]["organisations"][:documents_with_no_value])
    end

    should "have correct total number of options" do
      assert_equal(2, @output[:facets]["organisations"][:total_options])
    end

    should "have correct number of missing options" do
      assert_equal(0, @output[:facets]["organisations"][:missing_options])
    end
  end

  context "results with facets and a filter which matches nothing applied" do
    setup do
      @output = UnifiedSearchPresenter.new(
        sample_es_response("facets" => sample_facet_data),
        0,
        INDEX_NAMES,
        [text_filter("organisations", ["hm-cheesemakers"])],
        {"organisations" => facet_params(1)},
      ).present
    end

    should "have facets" do
      assert_contains @output.keys, :facets
    end

    should "have correct number of facets" do
      assert_equal 1, @output[:facets].length
    end

    should "have correct number of facet values" do
      assert_equal 2, @output[:facets]["organisations"][:options].length
    end

    should "have selected facet first" do
      assert_equal({
        :value => {"slug" => "hm-cheesemakers"},
        :documents => 0,
      }, @output[:facets]["organisations"][:options][0])
    end

    should "have unapplied facet value second" do
      assert_equal({
        :value => {"slug" => "hm-magic"},
        :documents => 7,
      }, @output[:facets]["organisations"][:options][1])
    end

    should "have correct number of documents with no value" do
      assert_equal(8, @output[:facets]["organisations"][:documents_with_no_value])
    end

    should "have correct total number of options" do
      assert_equal(2, @output[:facets]["organisations"][:total_options])
    end

    should "have correct number of missing options" do
      assert_equal(1, @output[:facets]["organisations"][:missing_options])
    end
  end

  context "results with facet counting only" do
    setup do
      @output = UnifiedSearchPresenter.new(
        sample_es_response("facets" => sample_facet_data),
        0,
        INDEX_NAMES,
        [],
        {"organisations" => facet_params(0)},
      ).present
    end

    should "have correct number of facets" do
      assert_equal 1, @output[:facets].length
    end

    should "have no facet values" do
      assert_equal 0, @output[:facets]["organisations"][:options].length
    end

    should "have correct number of documents with no value" do
      assert_equal(8, @output[:facets]["organisations"][:documents_with_no_value])
    end

    should "have correct total number of options" do
      assert_equal(2, @output[:facets]["organisations"][:total_options])
    end

    should "have correct number of missing options" do
      assert_equal(2, @output[:facets]["organisations"][:missing_options])
    end
  end

  context "results with facets sorted by ascending count" do
    setup do
      org_registry = sample_org_registry
      @output = search_presenter(
        es_response: {"facets" => sample_facet_data},
        facets: {"organisations" => facet_params(10, order: [[:count, 1]])},
        org_registry: org_registry
      ).present
    end

    should "have facets sorted by ascending count" do
      assert_equal [
        facet_response_hmrc,
        facet_response_magic,
      ], @output[:facets]["organisations"][:options]
    end
  end

  context "results with facets sorted by descending count" do
    setup do
      org_registry = sample_org_registry
      @output = search_presenter(
        es_response: {"facets" => sample_facet_data},
        facets: {"organisations" => facet_params(10, order: [[:count, -1]])},
        org_registry: org_registry
      ).present
    end

    should "have facets sorted by descending count" do
      assert_equal [
        facet_response_magic,
        facet_response_hmrc,
      ], @output[:facets]["organisations"][:options]
    end
  end

  context "results with facets sorted by ascending slug" do
    setup do
      org_registry = sample_org_registry
      @output = search_presenter(
        es_response: {"facets" => sample_facet_data},
        facets: {"organisations" => facet_params(10, order: [[:"value.slug", 1]])},
        org_registry: org_registry
      ).present
    end

    should "have facets sorted by ascending slug" do
      assert_equal [
        facet_response_magic,
        facet_response_hmrc,
      ], @output[:facets]["organisations"][:options]
    end
  end

  context "results with facets sorted by ascending link" do
    setup do
      org_registry = sample_org_registry
      @output = search_presenter(
        es_response: {"facets" => sample_facet_data},
        facets: {"organisations" => facet_params(10, order: [[:"value.link", 1]])},
        org_registry: org_registry
      ).present
    end

    should "have facets sorted by ascending link" do
      assert_equal [
        facet_response_magic,
        facet_response_hmrc,
      ], @output[:facets]["organisations"][:options]
    end
  end

  context "results with facets sorted by ascending title" do
    setup do
      org_registry = sample_org_registry
      @output = search_presenter(
        es_response: {"facets" => sample_facet_data},
        facets: {"organisations" => facet_params(10, order: [[:"value.title", 1]])},
        org_registry: org_registry
      ).present
    end

    should "have facets sorted by ascending title" do
      assert_equal [
        facet_response_hmrc,
        facet_response_magic,
      ], @output[:facets]["organisations"][:options]
    end
  end

  context "results with facets and an org registry" do
    setup do
      org_registry = sample_org_registry

      @output = UnifiedSearchPresenter.new(
        sample_es_response("facets" => sample_facet_data_with_topics),
        0,
        INDEX_NAMES,
        [],
        {"organisations" => facet_params(1), "topics" => facet_params(1)},
        {organisation_registry: org_registry},
        {organisations: org_registry},
      ).present
    end

    should "have facets" do
      assert_contains @output.keys, :facets
    end

    should "have correct number of facets" do
      assert_equal 2, @output[:facets].length
    end

    should "have correct number of facet values" do
      assert_equal 1, @output[:facets]["organisations"][:options].length
      assert_equal 1, @output[:facets]["topics"][:options].length
    end

    should "have org facet value expanded" do
      assert_equal({
        :value => {
          "link" => "/government/departments/hm-magic",
          "title" => "Ministry of Magic",
          "slug" => "hm-magic",
        },
        :documents=>7,
      }, @output[:facets]["organisations"][:options][0])
    end

    should "have topic facet value un-expanded" do
      assert_equal({
        :value => {"slug" => "unknown_topic"},
        :documents => 5,
      }, @output[:facets]["topics"][:options][0])
    end

    should "have correct number of documents with no value" do
      assert_equal(8, @output[:facets]["organisations"][:documents_with_no_value])
      assert_equal(3, @output[:facets]["topics"][:documents_with_no_value])
    end

    should "have correct total number of options" do
      assert_equal(2, @output[:facets]["organisations"][:total_options])
      assert_equal(2, @output[:facets]["topics"][:total_options])
    end

    should "have correct number of missing options" do
      assert_equal(1, @output[:facets]["organisations"][:missing_options])
      assert_equal(1, @output[:facets]["topics"][:missing_options])
    end
  end

  context "results with facet examples" do
    setup do
      org_registry = sample_org_registry

      @output = UnifiedSearchPresenter.new(
        sample_es_response("facets" => sample_facet_data),
        0,
        INDEX_NAMES,
        [],
        {"organisations" => facet_params(1),},
        {organisation_registry: org_registry},
        {organisations: org_registry},
        [],
        {"organisations" => {
          "hm-magic" => {
            "total" => 1,
            "examples" => [{"title" => "Ministry of Magic"}],
          }
        }}
      ).present
    end

    should "have facets" do
      assert_contains @output.keys, :facets
    end

    should "have correct number of facets" do
      assert_equal 1, @output[:facets].length
    end

    should "have correct number of facet values" do
      assert_equal 1, @output[:facets]["organisations"][:options].length
    end

    should "have org facet value expanded, and include examples" do
      assert_equal({
        :value => {
          "link" => "/government/departments/hm-magic",
          "title" => "Ministry of Magic",
          "slug" => "hm-magic",
          "example_info" => {
            "total" => 1,
            "examples" => [
              {"title" => "Ministry of Magic"},
            ],
          },
        },
        :documents=>7,
      }, @output[:facets]["organisations"][:options][0])
    end

    should "have correct number of documents with no value" do
      assert_equal(8, @output[:facets]["organisations"][:documents_with_no_value])
    end

    should "have correct total number of options" do
      assert_equal(2, @output[:facets]["organisations"][:total_options])
    end

    should "have correct number of missing options" do
      assert_equal(1, @output[:facets]["organisations"][:missing_options])
    end
  end

  context "suggested queries" do
    should "present suggestions in output" do
      @suggestions = [
        "self assessment",
        "tax returns"
      ]
      @output = UnifiedSearchPresenter.new(sample_es_response, 0, INDEX_NAMES, [], {}, {}, {}, @suggestions).present

      assert_equal ["self assessment", "tax returns"], @output[:suggested_queries]
    end

    should "default to an empty array when not present" do
      @output = UnifiedSearchPresenter.new(sample_es_response, 0, INDEX_NAMES, [], {}, {}, {}).present

      assert_equal [], @output[:suggested_queries]
    end
  end

  def text_filter(field_name, values)
    SearchParameterParser::TextFieldFilter.new(field_name, values)
  end
end
