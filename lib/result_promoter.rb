class ResultPromoter
  class PromotedResult < Struct.new(:id, :terms)
    def promoted_for?(term)
      terms.include?(term)
    end
  end

  def initialize
    @promoted_results = []
  end

  def add(id, terms)
    @promoted_results << PromotedResult.new(id, terms)
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