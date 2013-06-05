require 'ffi/aspell'

class Suggester
  def suggest(query_string)
    query_string.split("\s").map do |word|
      suggestion_for_a_word(word)
    end.join(" ")
  end

private
  def suggestion_for_a_word(word)
    speller.suggestions(word).map(&:downcase).first
  end

  def speller
    # Creating a new speller reads files off disk, so we want to do that as
    # little as possible. Therefore, memoize it as a singleton.
    @@speller ||= FFI::Aspell::Speller.new('en_GB')
  end
end
