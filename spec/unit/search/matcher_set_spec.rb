require 'spec_helper'

RSpec.describe 'MatcherSetTest' do
  it "should_match_strings" do
    matcher_set = Search::MatcherSet.new(%w(foo bang))
    assert matcher_set.include?("foo")
    refute matcher_set.include?("baz")
  end

  it "should_match_strings_case_insensitively" do
    matcher_set = Search::MatcherSet.new(["foo"])
    assert matcher_set.include?("Foo")
  end

  it "should_match_regexes" do
    matcher_set = Search::MatcherSet.new([/oo/])
    assert matcher_set.include?("Foo")
    refute matcher_set.include?("Fopo")
  end

  it "matchers_should_be_immutable" do
    members = ["foo"]
    matcher_set = Search::MatcherSet.new(members)
    members.pop
    assert matcher_set.include?("foo")
  end
end
