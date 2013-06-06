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
    assert_equal ["self spelling"], suggester.suggestions("self speling")
  end

  def test_does_not_suggest_the_input
    suggester = Suggester.new
    assert_equal [], suggester.suggestions("jobs are nice")
  end

  def test_should_not_remove_a_word_with_no_suggestions
    # if ffi-aspell has no suggestions, it returns an empty array
    suggester = Suggester.new
    assert_equal ["notinthedictionary spelling"], suggester.suggestions("notinthedictionary speling")
  end

  def test_should_not_change_the_letter_case_of_words
    # Aspell will sometimes suggest the word given with different letter cases.
    # Sometimes this is fine (eg "paris" => "Paris").
    # Sometimes it's unhelpful (eg "in" => "IN").
    # We want to retain the capitalisation given.
    suggester = Suggester.new
    assert_equal ["in spelling"], suggester.suggestions("in speling")
    assert_equal ["MoD spelling"], suggester.suggestions("MoD speling")
  end
end
