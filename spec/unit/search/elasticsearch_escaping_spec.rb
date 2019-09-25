require "spec_helper"

RSpec.describe Search::Escaping do
  subject do
    instance = double
    instance.extend(described_class)
    instance
  end

  it "escapes the query for lucene chars" do
    expect(subject.escape("how?")).to eq("how\\?")
  end

  it "escapes the query for lucene booleans" do
    expect(subject.escape("fish AND chips")).to eq('fish "AND" chips')
  end
end
