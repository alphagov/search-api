class PromotedResult
  attr_reader :link, :terms

  def initialize(link, terms)
    @link = link
    @terms = terms.is_a?(Array) ? terms : split_terms(terms)
  end

  def promoted_for?(term)
    terms.include?(term)
  end

private
  def split_terms(terms)
    (terms || "").split(/ +/).reject {|t| t.size == 0}
  end
end