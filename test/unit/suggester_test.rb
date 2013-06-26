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

  def test_does_not_suggest_removing_multiple_spaces
    suggester = Suggester.new
    assert_equal [], suggester.suggestions("jobs  are nice")
  end

  def test_does_not_suggest_removing_trailing_spaces
    suggester = Suggester.new
    assert_equal [], suggester.suggestions("jobs  ")
  end

  def test_does_not_suggest_removing_leading_spaces
    suggester = Suggester.new
    assert_equal [], suggester.suggestions("  jobs")
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

  def test_should_not_make_suggestions_for_words_in_ignore_list
    suggester = Suggester.new(ignore: ["DFT"])
    assert_equal ["DFT badger"], suggester.suggestions("DFT bagder")
  end

  def test_should_not_suggest_words_in_blacklist
    suggester = Suggester.new(blacklist: ["fuck", "fucks"])
    assert_equal ["funk"], suggester.suggestions("fcuk") # funk is the third suggestion
  end

  def test_should_not_suggest_words_in_blacklist_even_when_split
    suggester = Suggester.new(blacklist: ["penis"])
    assert_equal ["pension"], suggester.suggestions("penison") # generates "penis on"
  end

  def test_should_not_suggest_words_in_blacklist_even_when_hyphenated
    suggester = Suggester.new(blacklist: ["penis"])
    assert_equal ["pension"], suggester.suggestions("penison") # generates "penis-on"
  end

  def test_blacklist_is_applied_to_whole_words_only
    suggester = Suggester.new(blacklist: ["ass"])
    assert_equal ["class"], suggester.suggestions("cluss") # top suggestion is "class"
  end
end
