require "test_helper"
require "govuk_search_presenter"

class GovukSearchPresenterTest < ShouldaUnitTestCase

  context "no streams" do
    setup do
      @presenter = GovukSearchPresenter.new({})
    end

    should "present an empty set of streams" do
      assert_equal({"streams" => {}}, @presenter.present)
    end
  end

  context "unknown streams" do
    should "reject unknown streams" do
      assert_raises ArgumentError do
        GovukSearchPresenter.new("cheese" => [])
      end
    end

    should "report unknown streams in the exception" do
      begin
        GovukSearchPresenter.new("cheese" => []) and flunk
      rescue ArgumentError => e
        assert e.message.include? "cheese"
      end
    end
  end

  context "multiple streams" do
    def stub_presenter
      stub(present: {"results" => []})
    end

    setup do
      @top_results = stub("top results")
      @si_results = stub("S&I results")
      @presenter = GovukSearchPresenter.new(
        "top-results" => @top_results,
        "services-information" => @si_results
      )
    end

    should "instantiate a ResultSetPresenter per stream" do
      ResultSetPresenter.expects(:new).with(@top_results, {}).returns(stub_presenter)
      ResultSetPresenter.expects(:new).with(@si_results, {}).returns(stub_presenter)
      @presenter.present
    end

    should "include results from each stream" do
      ResultSetPresenter.stubs(:new).returns(stub_presenter)
      output = @presenter.present
      assert_equal(
        ["top-results", "services-information"].to_set,
        output["streams"].keys.to_set
      )
    end

    should "insert titles" do
      ResultSetPresenter.stubs(:new).returns(stub_presenter)
      output = @presenter.present
      streams = output["streams"]

      assert_equal "Top results", streams["top-results"]["title"]
      assert_equal "Services and information", streams["services-information"]["title"]
    end
  end

  context "with ResultSetPresenter context" do
    setup do
      @top_results = stub("top results")
      @si_results = stub("S&I results")
      presenters = {
        "top-results" => @top_results
      }
      @context = stub("presenter context")
      @presenter = GovukSearchPresenter.new(
        {"top-results" => @top_results},
        @context
      )
    end

    should "pass the presenter context on to child presenters" do
      ResultSetPresenter.expects(:new)
          .with(@top_results, @context)
          .returns(stub_presenter)
      @presenter.present
    end
  end
end
