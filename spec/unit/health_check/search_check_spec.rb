require 'spec_helper'


RSpec.describe HealthCheck::SearchCheck do
  before do
    @search_results = ["any-old-thing"]
  end

  context "#result" do
    it "delegate to it's corresponding results class" do
      expect(HealthCheck::SearchCheckResult).to receive(:new).with({ check: subject, search_results:  @search_results })
      subject.result(@search_results)
    end
  end

  context "#valid_imperative?" do
    it "be true only for valid imperatives" do
      expect(subject.tap { |c| c.imperative = "should" }).to be_valid_imperative
      expect(subject.tap { |c| c.imperative = "should not" }).to be_valid_imperative
      expect(subject.tap { |c| c.imperative = "anything else" }).not_to be_valid_imperative
    end
  end

  context "#valid_path?" do
    it "be true only for valid paths" do
      expect(subject.tap { |c| c.path = "/" }).to be_valid_path
      expect(subject.tap { |c| c.path = "foo" }).not_to be_valid_path
      expect(subject.tap { |c| c.path = "" }).not_to be_valid_path
      expect(subject.tap { |c| c.path = nil }).not_to be_valid_path
    end
  end

  context "#valid_search_term?" do
    it "be true only for non-blank search terms" do
      expect(subject.tap { |c| c.search_term = "foo" }).to be_valid_search_term
      expect(subject.tap { |c| c.search_term = "" }).not_to be_valid_search_term
      expect(subject.tap { |c| c.search_term = nil }).not_to be_valid_search_term
    end
  end

  context "valid_weight?" do
    it "be true only for weights greater than 0" do
      expect(subject.tap { |c| c.weight = -1 }).not_to be_valid_weight
      expect(subject.tap { |c| c.weight = 0 }).not_to be_valid_weight
      expect(subject.tap { |c| c.weight = 1 }).to be_valid_weight
    end
  end
end
