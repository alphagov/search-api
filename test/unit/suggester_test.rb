require "test_helper"
require "suggester"

class SuggesterTest < MiniTest::Unit::TestCase
  def test_make_suggestions
    suggester = Suggester.new
    assert_equal "spelling", suggester.suggest("speling")
  end

  def test_make_suggestions_for_a_phrase
    suggester = Suggester.new
    assert_equal "spelling is bad", suggester.suggest("speling is badd")
  end
end
