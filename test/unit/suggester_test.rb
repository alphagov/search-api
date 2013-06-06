require "test_helper"
require "suggester"

class SuggesterTest < MiniTest::Unit::TestCase
  def test_make_a_suggestion
    suggester = Suggester.new
    assert_equal ["spelling"], suggester.suggestions("speling")
  end

  def test_make_a_suggestion_for_a_phrase
    suggester = Suggester.new
    assert_equal ["spelling is bad"], suggester.suggestions("speling is badd")
  end
end
