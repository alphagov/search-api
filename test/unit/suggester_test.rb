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

  def test_retains_correctly_spelled_words
    suggester = Suggester.new
    # "self" will generate suggestions for "self", "shelf", "ELF"...
    assert_equal ["self"], suggester.suggestions("self")
  end

  def test_should_not_remove_a_word_with_no_suggestions
    # if ffi-aspell has no suggestions, it returns an empty array
    FFI::Aspell::Speller.any_instance.expects(:suggestions).returns([])
    suggester = Suggester.new
    assert_equal ["notinthedictionary"], suggester.suggestions("notinthedictionary")
  end
end
