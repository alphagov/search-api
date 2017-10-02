require 'spec_helper'

RSpec.describe Search::Escaping do
  subject do
    instance = double
    instance.extend(Search::Escaping)
    instance
  end

  it "escapes_the_query_for_lucene_chars" do
    expect(subject.escape("how?")).to eq("how\\?")
  end

  it "escapes_the_query_for_lucene_booleans" do
    expect(subject.escape("fish AND chips")).to eq('fish "AND" chips')
  end
end
