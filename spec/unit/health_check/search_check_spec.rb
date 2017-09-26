require 'spec_helper'

module HealthCheck
  RSpec.describe 'SearchCheckTest', tags: ['shoulda'] do
    before do
      @subject = SearchCheck.new
      @search_results = ["any-old-thing"]
    end

    context "#result" do
      it "delegate to it's corresponding results class" do
        expect(SearchCheckResult).to receive(:new).with({ check: @subject, search_results:  @search_results })
        @subject.result(@search_results)
      end
    end

    context "#valid_imperative?" do
      it "be true only for valid imperatives" do
        assert @subject.tap { |c| c.imperative = "should" }.valid_imperative?
        assert @subject.tap { |c| c.imperative = "should not" }.valid_imperative?
        refute @subject.tap { |c| c.imperative = "anything else" }.valid_imperative?
      end
    end

    context "#valid_path?" do
      it "be true only for valid paths" do
        assert @subject.tap { |c| c.path = "/" }.valid_path?
        refute @subject.tap { |c| c.path = "foo" }.valid_path?
        refute @subject.tap { |c| c.path = "" }.valid_path?
        refute @subject.tap { |c| c.path = nil }.valid_path?
      end
    end

    context "#valid_search_term?" do
      it "be true only for non-blank search terms" do
        assert @subject.tap { |c| c.search_term = "foo" }.valid_search_term?
        refute @subject.tap { |c| c.search_term = "" }.valid_search_term?
        refute @subject.tap { |c| c.search_term = nil }.valid_search_term?
      end
    end

    context "valid_weight?" do
      it "be true only for weights greater than 0" do
        refute @subject.tap { |c| c.weight = -1 }.valid_weight?
        refute @subject.tap { |c| c.weight = 0 }.valid_weight?
        assert @subject.tap { |c| c.weight = 1 }.valid_weight?
      end
    end
  end
end
