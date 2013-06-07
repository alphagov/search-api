require 'promoted_result'

class ResultPromoter
  def initialize(promoted_results)
    @promoted_results = promoted_results
  end

  def promoted_terms_in(query)
    terms = query.downcase.gsub(/[^a-z]/, " ").split(/ +/).uniq
    terms.select do |term|
      @promoted_results.any? do |promoted_result|
        promoted_result.promoted_for?(term)
      end
    end
  end

  def with_promotion(document_hash)
    promoted_terms = @promoted_results.select do |promoted_result|
      document_hash["link"] == promoted_result.link
    end.map do |promoted_result|
      promoted_result.terms
    end.flatten
    document_hash.dup.tap do |new_hash|
      if promoted_terms.any?
        new_hash["promoted_for"] = promoted_terms.join(" ")
      else
        new_hash.delete("promoted_for")
      end
    end
  end
end