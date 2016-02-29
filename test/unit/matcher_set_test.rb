require "test_helper"
require "search/matcher_set"

class MatcherSetTest < MiniTest::Unit::TestCase
  def test_should_match_strings
    matcher_set = Search::MatcherSet.new(%w(foo bang))
    assert matcher_set.include?("foo")
    refute matcher_set.include?("baz")
  end

  def test_should_match_strings_case_insensitively
    matcher_set = Search::MatcherSet.new(["foo"])
    assert matcher_set.include?("Foo")
  end

  def test_should_match_regexes
    matcher_set = Search::MatcherSet.new([/oo/])
    assert matcher_set.include?("Foo")
    refute matcher_set.include?("Fopo")
  end

  def test_matchers_should_be_immutable
    members = ["foo"]
    matcher_set = Search::MatcherSet.new(members)
    members.pop
    assert matcher_set.include?("foo")
  end
end
