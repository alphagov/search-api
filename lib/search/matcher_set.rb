module Search
  class MatcherSet
    attr_reader :matchers

    # matchers - an array of strings and/or regexes.
    #            Strings are matched ignoring case.
    def initialize(matchers)
      @matchers = matchers.dup
    end

    # Does this MatcherSet match the supplied string?
    def include?(candidate)
      @matchers.any? do |matcher|
        case matcher
        when String
          # casecmp returns 0 when the strings are equivalent, ignoring case
          candidate.casecmp(matcher).zero?
        when Regexp
          # match returns nil if no match, or a MatchData if any matches
          candidate.match(matcher).present?
        else
          raise "Unexpected matcher type: #{matcher}"
        end
      end
    end
  end
end
