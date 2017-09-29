require 'spec_helper'

RSpec.describe Search::Escaping do
  subject do
    instance = double
    instance.extend(Search::Escaping)
    instance
  end

  it "escapes_the_query_for_lucene_chars" do
    expect("how\\?").to eq(subject.escape("how?"))
  end

  it "escapes_the_query_for_lucene_booleans" do
    expect('fish "AND" chips').to eq(subject.escape("fish AND chips"))
  end
end
