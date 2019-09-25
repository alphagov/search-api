require "spec_helper"

RSpec.describe Search::MatcherSet do
  it "matches strings" do
    matcher_set = described_class.new(%w(foo bang))
    expect(matcher_set).to include("foo")
    expect(matcher_set).not_to include("baz")
  end

  it "matches strings case insensitively" do
    matcher_set = described_class.new(%w[foo])
    expect(matcher_set).to include("Foo")
  end

  it "matches regexes" do
    matcher_set = described_class.new([/oo/])
    expect(matcher_set).to include("Foo")
    expect(matcher_set).not_to include("Fopo")
  end

  it "matchers should be immutable" do
    members = %w[foo]
    matcher_set = described_class.new(members)
    members.pop
    expect(matcher_set).to include("foo")
  end
end
