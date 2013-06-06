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

  def test_should_not_change_the_letter_case_of_words
    # Aspell will sometimes suggest the word given with different letter cases.
    # Sometimes this is fine (eg "paris" => "Paris").
    # Sometimes it's unhelpful (eg "in" => "IN").
    # We want to retain the capitalisation given.
    suggester = Suggester.new
    FFI::Aspell::Speller.any_instance.expects(:suggestions).with("in").returns(["IN"])
    assert_equal ["in"], suggester.suggestions("in")
    FFI::Aspell::Speller.any_instance.expects(:suggestions).with("MoD").returns(["mod"])
    assert_equal ["MoD"], suggester.suggestions("MoD")
  end
end
