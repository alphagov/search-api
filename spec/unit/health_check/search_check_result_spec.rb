require 'spec_helper'

RSpec.describe HealthCheck::SearchCheckResult, tags: ['shoulda'] do
  subject { described_class.new(check: check, search_results: search_results) }

  context ".build" do
    context "'should' checks" do
      context 'desired result is within the desired ranking' do
        let(:check) { HealthCheck::SearchCheck.new("carmen", "should", "/a", 1, 200) }
        let(:search_results) { ["https://www.gov.uk/a"] }

        it "return a successful Result" do
          assert_equal true, subject.success
          assert_equal "FOUND", subject.found_label
          assert_equal "PASS", subject.success_label
        end
      end

      context "desired result is outside of the desired ranking" do
        let(:check) { HealthCheck::SearchCheck.new("carmen", "should", "/a", 1, 200) }
        let(:search_results) { ["https://www.gov.uk/b", "https://www.gov.uk/a"] }

        it "return a failure Result" do
          refute subject.success
          assert_equal "FOUND", subject.found_label
          assert_equal "FAIL", subject.success_label
        end
      end

      context "desired result isn't in the results" do
        let(:check) { HealthCheck::SearchCheck.new("carmen", "should", "/a", 1, 200) }
        let(:search_results) { ["https://www.gov.uk/b", "https://www.gov.uk/c"] }

        it "return a failure Result" do
          refute subject.success
          assert_equal "NOT FOUND", subject.found_label
          assert_equal "FAIL", subject.success_label
        end
      end
    end
  end


  context "'should not' checks" do
    context "an undesirable result is in the top N" do
      let(:check) { HealthCheck::SearchCheck.new("carmen", "should not", "/a", 1, 200) }
      let(:search_results) { ["https://www.gov.uk/a", "https://www.gov.uk/b"] }

      it "fail" do
        refute subject.success
        assert_equal "FOUND", subject.found_label
        assert_equal "FAIL", subject.success_label
      end
    end

    context "an undesirable result is after the top N" do
      let(:check) { HealthCheck::SearchCheck.new("carmen", "should not", "/a", 1, 200) }
      let(:search_results) { ["https://www.gov.uk/b", "https://www.gov.uk/a"] }

      it "pass" do
        assert subject.success
        assert_equal "FOUND", subject.found_label
        assert_equal "PASS", subject.success_label
      end
    end

    context "an undesirable result doesn't appear" do
      let(:check) { HealthCheck::SearchCheck.new("carmen", "should not", "/x", 1, 200) }
      let(:search_results) { ["https://www.gov.uk/a", "https://www.gov.uk/b"] }

      it "pass" do
        assert subject.success
        assert_equal "NOT FOUND", subject.found_label
        assert_equal "PASS", subject.success_label
      end
    end
  end
end
