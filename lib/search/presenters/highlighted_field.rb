module Search
  class HighlightedField
    def initialize(name, raw_result)
      @name = name
      @raw_result = raw_result
    end

    def highlighted
      # `highlight` will be missing if none of the search terms match what's in
      # the field, eg. when displaying best bets.
      raw_result["highlight"] &&
        (raw_result["highlight"][name].to_a.first || raw_result["highlight"]["#{name}.synonym"].to_a.first)
    end

    def original
      Rack::Utils.escape_html(raw_result["_source"][name] || raw_result["_source"]["#{name}.synonym"])
    end

  private

    attr_reader :name, :raw_result
  end
end
