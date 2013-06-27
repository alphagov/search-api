require 'ffi/aspell'

class Suggester
  # "options" is a hash with symbol keys:
  #   :ignore - Words or patterns that shouldn't generate spelling suggestions.
  #             Any object that responds to `include?`, eg Array or a MatcherSet.
  #             If passing an array of strings, it will be case insensitive.
  #   :blacklist - a list of words that shouldn't be suggested.
  #             Any object that responds to `include?`, eg Array or a MatcherSet.
  #             If passing an array of strings, it will be case insensitive.
  def initialize(options={})
    @ignore_list = options[:ignore] || []
    @blacklist = options[:blacklist] || []
  end

  # Returns an array of suggested corrections for a query_string.
  #
  # Currently only returns a single suggestion, where each word:
  #  * is retained if in the dictionary, otherwise
  #  * is replaced by it's most likely correction
  def suggestions(query_string)
    suggested_string = query_string.split("\s").map do |word|
      suggestion_for_a_word(word) || word
    end.join(" ")

    if suggested_string.downcase == query_string.split("\s").join(" ").downcase
      # don't suggest the input, even if the case has changed
      []
    else
      [suggested_string]
    end
  end

private
  # Return the best suggestion for the word, or nil if no suggestions
  def suggestion_for_a_word(word)
    if @ignore_list.include?(word)
      nil
    else
      acceptable_suggestion = speller.suggestions(word).detect do |suggestion|
        suggestion_words = suggestion.split(/[\s+|\-]/)
        suggestion_words.none? { |suggested_word| @blacklist.include?(suggested_word) }
      end
      if acceptable_suggestion.nil?
        nil
      # If the word is the same (ignoring differences in letter cases),
      # retain the user's letter cases.
      elsif acceptable_suggestion.downcase == word.downcase
        nil
      else
        acceptable_suggestion
      end
    end
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
