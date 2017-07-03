require "test_helper"
require "search/escaping"

class SearchEscapingTest < MiniTest::Unit::TestCase
  class Dummy
    include Search::Escaping
  end

  def test_escapes_the_query_for_lucene_chars
    assert_equal "how\\?", Dummy.new.escape("how?")
  end

  def test_escapes_the_query_for_lucene_booleans
    assert_equal 'fish "AND" chips', Dummy.new.escape("fish AND chips")
  end
end
