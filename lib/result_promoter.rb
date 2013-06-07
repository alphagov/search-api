require 'promoted_result'

class ResultPromoter
  def initialize
    @promoted_results = []
  end

  def add(link, terms)
    @promoted_results << PromotedResult.new(link, terms)
  end

  def promoted_terms_in(query)
    terms = query.downcase.gsub(/[^a-z]/, " ").split(/ +/).uniq
    terms.select do |term|
      @promoted_results.any? do |promoted_result|
        promoted_result.promoted_for?(term)
      end
    end
  end
end