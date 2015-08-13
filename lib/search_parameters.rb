# SearchParameters
#
# Value object that holds the parsed parameters for a search.
class SearchParameters
  attr_accessor :query, :order, :start, :count, :return_fields, :facets,
                :filters, :debug

  def initialize(params = {})
    params = { facets: [], filters: {}, debug: {} }.merge(params)
    params.each do |k, v|
      public_send("#{k}=", v)
    end
  end
end
