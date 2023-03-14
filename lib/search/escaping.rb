module Search
  module Escaping
    LUCENE_SPECIAL_CHARACTERS = begin
      chars = %w[+ - && || ! ( ) { } [ ] ^ " ~ * ? : \\ /]
      escaped = chars.map { |s| Regexp.escape(s) }.join("|")
      Regexp.new("(#{escaped})")
    end

    LUCENE_BOOLEANS = /\b(AND|OR|NOT)\b/

    def escape(string)
      # 6 slashes =>
      #  ruby reads it as 3 backslashes =>
      #    the first 2 =>
      #      go into the regex engine which reads it as a single literal backslash
      #    the last one combined with the "1" to insert the first match group
      special_chars_escaped = string.gsub(LUCENE_SPECIAL_CHARACTERS, '\\\\\1')

      # Map something like 'fish AND chips' to 'fish "AND" chips', to avoid
      # Lucene trying to parse it as a query conjunction
      special_chars_escaped.gsub(LUCENE_BOOLEANS, '"\1"')
    end
  end
end
