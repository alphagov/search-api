require 'ffi/aspell'

class Suggester
  # "options" is a hash with symbol keys:
  #   :ignore - a list of words that shouldn't generate spelling suggestions.
  #             Any object that responds to ``include?(string)`` will do, eg Array.
  def initialize(options={})
    @ignore_list = options[:ignore] || []
  end

  # Returns an array of suggested corrections for a query_string.
  #
  # Currently only returns a single suggestion, where each word:
  #  * is retained if in the dictionary, otherwise
  #  * is replaced by it's most likely correction
  def suggestions(query_string)
    suggested_string = query_string.split("\s").map do |word|
      suggested_word = suggestion_for_a_word(word)
      if suggested_word.nil?
        word
      # If the word is the same (ignoring differences in letter cases),
      # retain the user's letter cases.
      elsif suggested_word.downcase == word.downcase
        word
      else
        suggested_word
      end
    end.join(" ")

    if suggested_string.downcase == query_string.split("\s").join(" ").downcase
      # don't suggest the input, even if the case has changed
      []
    else
      [suggested_string]
    end
  end

private
  def suggestion_for_a_word(word)
    speller.suggestions(word).first unless @ignore_list.include?(word)
  end

  def speller
    # Creating a new speller reads files off disk, so we want to do that as
    # little as possible. Therefore, memoize it as a singleton.
    #
    # We need to specify an explicit encoding, as deployed environments will
    # not necessarily have locale information with which to determine a default
    # encoding; if this happens, the Aspell library will return an encoding
    # value of "none", which causes any attempts to convert the encoding for
    # spelling suggestions to fail. Since all search requests get passed
    # through the Speller, this breaks any requests through Rummager.
    @@speller ||= FFI::Aspell::Speller.new('en_GB', encoding: 'utf-8')
  end
end
