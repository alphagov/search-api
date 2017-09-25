require 'spec_helper'

RSpec.describe 'SearchEscapingTest' do
  class Dummy
    include Search::Escaping
  end

  it "escapes_the_query_for_lucene_chars" do
    assert_equal "how\\?", Dummy.new.escape("how?")
  end

  it "escapes_the_query_for_lucene_booleans" do
    assert_equal 'fish "AND" chips', Dummy.new.escape("fish AND chips")
  end
end
