require 'spec_helper'

RSpec.describe Search::Escaping do
  subject do
    instance = double
    instance.extend(Search::Escaping)
    instance
  end

  it "escapes_the_query_for_lucene_chars" do
    assert_equal "how\\?", subject.escape("how?")
  end

  it "escapes_the_query_for_lucene_booleans" do
    assert_equal 'fish "AND" chips', subject.escape("fish AND chips")
  end
end
