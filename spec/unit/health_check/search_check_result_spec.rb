require 'spec_helper'

RSpec.describe HealthCheck::SearchCheckResult do
  subject { described_class.new(check: check, search_results: search_results) }

  context ".build" do
    context "'should' checks" do
      context 'desired result is within the desired ranking' do
        let(:check) { HealthCheck::SearchCheck.new("carmen", "should", "/a", 1, 200) }
        let(:search_results) { ["https://www.gov.uk/a"] }

        it "return a successful Result" do
          expect(true).to eq(subject.success)
          expect(subject.found_label).to eq("FOUND")
          expect(subject.success_label).to eq("PASS")
        end
      end

      context "desired result is outside of the desired ranking" do
        let(:check) { HealthCheck::SearchCheck.new("carmen", "should", "/a", 1, 200) }
        let(:search_results) { ["https://www.gov.uk/b", "https://www.gov.uk/a"] }

        it "return a failure Result" do
          expect(subject.success).to be_falsey
          expect(subject.found_label).to eq("FOUND")
          expect(subject.success_label).to eq("FAIL")
        end
      end

      context "desired result isn't in the results" do
        let(:check) { HealthCheck::SearchCheck.new("carmen", "should", "/a", 1, 200) }
        let(:search_results) { ["https://www.gov.uk/b", "https://www.gov.uk/c"] }

        it "return a failure Result" do
          expect(subject.success).to be_falsey
          expect(subject.found_label).to eq("NOT FOUND")
          expect(subject.success_label).to eq("FAIL")
        end
      end
    end
  end


  context "'should not' checks" do
    context "an undesirable result is in the top N" do
      let(:check) { HealthCheck::SearchCheck.new("carmen", "should not", "/a", 1, 200) }
      let(:search_results) { ["https://www.gov.uk/a", "https://www.gov.uk/b"] }

      it "fail" do
        expect(subject.success).to be_falsey
        expect(subject.found_label).to eq("FOUND")
        expect(subject.success_label).to eq("FAIL")
      end
    end

    context "an undesirable result is after the top N" do
      let(:check) { HealthCheck::SearchCheck.new("carmen", "should not", "/a", 1, 200) }
      let(:search_results) { ["https://www.gov.uk/b", "https://www.gov.uk/a"] }

      it "pass" do
        expect(subject.success).to be_truthy
        expect(subject.found_label).to eq("FOUND")
        expect(subject.success_label).to eq("PASS")
      end
    end

    context "an undesirable result doesn't appear" do
      let(:check) { HealthCheck::SearchCheck.new("carmen", "should not", "/x", 1, 200) }
      let(:search_results) { ["https://www.gov.uk/a", "https://www.gov.uk/b"] }

      it "pass" do
        expect(subject.success).to be_truthy
        expect(subject.found_label).to eq("NOT FOUND")
        expect(subject.success_label).to eq("PASS")
      end
    end
  end
end
