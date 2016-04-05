require_relative "../../test_helper"
require "health_check/search_check_result"
require "health_check/search_check"

module HealthCheck
  class SearchCheckResultTest < ShouldaUnitTestCase
    def setup
      @subject = SearchCheckResult
    end

    def build_result
      @result = @subject.new(check: @check, search_results: @search_results)
    end

    context ".build" do
      context "'should' checks" do
        context 'desired result is within the desired ranking' do
          should "return a successful Result" do
            @check = SearchCheck.new("carmen", "should", "/a", 1, 200)
            @search_results = ["https://www.gov.uk/a"]

            build_result

            assert_equal true, @result.success
            assert_equal 200, @result.score
            assert_equal 200, @result.possible_score
            assert_equal "FOUND", @result.found_label
            assert_equal "PASS", @result.success_label
          end
        end

        context "desired result is outside of the desired ranking" do
          should "return a failure Result" do
            @check = SearchCheck.new("carmen", "should", "/a", 1, 200)
            @search_results = ["https://www.gov.uk/b", "https://www.gov.uk/a"]

            build_result

            refute @result.success
            assert_equal 0, @result.score
            assert_equal 200, @result.possible_score
            assert_equal "FOUND", @result.found_label
            assert_equal "FAIL", @result.success_label
          end
        end

        context "desired result isn't in the results" do
          should "return a failure Result" do
            @check = SearchCheck.new("carmen", "should", "/a", 1, 200)
            @search_results = ["https://www.gov.uk/b", "https://www.gov.uk/c"]

            build_result

            refute @result.success
            assert_equal 0, @result.score
            assert_equal 200, @result.possible_score
            assert_equal "NOT FOUND", @result.found_label
            assert_equal "FAIL", @result.success_label
          end
        end
      end
    end


    context "'should not' checks" do
      context "an undesirable result is in the top N" do
        should "fail" do
          @check = SearchCheck.new("carmen", "should not", "/a", 1, 200)
          @search_results = ["https://www.gov.uk/a", "https://www.gov.uk/b"]

          build_result

          refute @result.success
          assert_equal "FOUND", @result.found_label
          assert_equal "FAIL", @result.success_label
        end
      end

      context "an undesirable result is after the top N" do
        should "pass" do
          @check = SearchCheck.new("carmen", "should not", "/a", 1, 200)
          @search_results = ["https://www.gov.uk/b", "https://www.gov.uk/a"]

          build_result

          assert @result.success
          assert_equal "FOUND", @result.found_label
          assert_equal "PASS", @result.success_label
        end
      end

      context "an undesirable result doesn't appear" do
        should "pass" do
          @check = SearchCheck.new("carmen", "should not", "/x", 1, 200)
          @search_results = ["https://www.gov.uk/a", "https://www.gov.uk/b"]

          build_result

          assert @result.success
          assert_equal "NOT FOUND", @result.found_label
          assert_equal "PASS", @result.success_label
        end
      end
    end
  end
end
