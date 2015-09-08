# SearchParameters
#
# Value object that holds the parsed parameters for a search.
class SearchParameters
  attr_accessor :query, :order, :start, :count, :return_fields, :facets,
                :filters, :debug, :suggest

  def initialize(params = {})
    params = { facets: [], filters: {}, debug: {}, return_fields: [] }.merge(params)
    params.each do |k, v|
      public_send("#{k}=", v)
    end
  end

  def field_requested?(name)
    return_fields.include?(name)
  end

  def disable_popularity?
    debug[:disable_popularity]
  end

  def disable_synonyms?
    debug[:disable_synonyms]
  end

  def enable_new_weighting?
    debug[:new_weighting]
  end

  def disable_best_bets?
    debug[:disable_best_bets]
  end

  def suggest_spelling?
    query && suggest.include?('spelling')
  end
end
