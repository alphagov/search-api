require 'spec_helper'

RSpec.describe Search::MatcherSet do
  it "should_match_strings" do
    matcher_set = described_class.new(%w(foo bang))
    expect(matcher_set).to include("foo")
    expect(matcher_set).not_to include("baz")
  end

  it "should_match_strings_case_insensitively" do
    matcher_set = described_class.new(["foo"])
    expect(matcher_set).to include("Foo")
  end

  it "should_match_regexes" do
    matcher_set = described_class.new([/oo/])
    expect(matcher_set).to include("Foo")
    expect(matcher_set).not_to include("Fopo")
  end

  it "matchers_should_be_immutable" do
    members = ["foo"]
    matcher_set = described_class.new(members)
    members.pop
    expect(matcher_set).to include("foo")
  end
end
