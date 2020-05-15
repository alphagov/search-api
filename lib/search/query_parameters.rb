module Search
  # Value object that holds the parsed parameters for a search.
  class QueryParameters
    attr_accessor :query,
                  :parsed_query,
                  :similar_to,
                  :order,
                  :start,
                  :count,
                  :return_fields,
                  :aggregates,
                  :aggregate_name,
                  :filters,
                  :debug,
                  :suggest,
                  :is_quoted_phrase,
                  :ab_tests,
                  :cluster,
                  :search_config

    # starts and ends with quotes with no quotes in between, with or without
    # leading or trailing whitespace
    QUOTED_STRING_REGEX = /^\s*"[^"]+"\s*$/.freeze

    def initialize(params = {})
      params = {
        aggregates: [],
        filters: {},
        debug: {},
        return_fields: [],
        ab_tests: {},
        cluster: Clusters.default_cluster,
        search_config: SearchConfig.default_instance,
      }.merge(params)
      params.each do |k, v|
        public_send("#{k}=", v)
      end
      determine_if_quoted_phrase
    end

    def quoted_search_phrase?
      @is_quoted_phrase
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

    def disable_best_bets?
      debug[:disable_best_bets]
    end

    def disable_boosting?
      debug[:disable_boosting]
    end

    def show_query?
      debug[:show_query]
    end

    def suggest_autocomplete?
      query && suggest.include?("autocomplete")
    end

    def suggest_spelling?
      query && (suggest.include?("spelling") || suggest.include?("spelling_with_highlighting"))
    end

    def rerank
      RelevanceHelpers.ltr_enabled? && [nil, "relevance"].include?(order) && ab_tests[:relevance] != "disable"
    end

    def use_shingles?
      ab_tests[:shingles] == "B"
    end

    def model_variant
      return unless model_variants.include? ab_tests[:mv]

      ab_tests[:mv]
    end

    def model_variants
      @model_variants ||= ENV.fetch("TENSORFLOW_SAGEMAKER_VARIANTS", "").split(",")
    end

  private

    def determine_if_quoted_phrase
      if @query =~ QUOTED_STRING_REGEX
        @is_quoted_phrase = true
      else
        @is_quoted_phrase = false
      end
    end
  end
end
