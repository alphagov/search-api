require "learn_to_rank/explain_scores"
require "learn_to_rank/organisation_enums"
require "learn_to_rank/format_enums"

module LearnToRank
  class Features
    include OrganisationEnums
    include FormatEnums
    # Features takes some values and translates them to features
    def initialize(
      explain: {},
      popularity: 0,
      es_score: 0,
      title: "",
      description: "",
      link: "",
      public_timestamp: "",
      format: nil,
      organisation_content_ids: [],
      indexable_content: "",
      query: "",
      updated_at: ""
    )
      @popularity = popularity || 0
      @es_score = es_score || 0
      @explain_scores = LearnToRank::ExplainScores.new(explain)
      @title = title || ""
      @description = description || ""
      @link = link || ""
      @public_timestamp = get_timestamp(public_timestamp)
      @format = get_format(format)
      @organisation = get_org(organisation_content_ids)
      @query_length = get_query_length(query)
      @indexable_content = indexable_content || ""
      @updated_at = get_timestamp(updated_at)
    end

    def as_hash
      {
        "1" => Float(@popularity),
        "2" => Float(@es_score),
        "3" => Float(explain_scores.title_score || 0),
        "4" => Float(explain_scores.description_score || 0),
        "5" => Float(explain_scores.indexable_content_score || 0),
        "6" => Float(explain_scores.all_searchable_text_score || 0),
        "7" => Float(title.length),
        "8" => Float(description.length),
        "9" => Float(link.length),
        "10" => Float(public_timestamp),
        "11" => Float(format),
        "12" => Float(organisation),
        "13" => Float(query_length),
        "14" => Float(indexable_content.length),
        "15" => Float(link_slash_count),
        "16" => Float(updated_at),
      }
    end

  private

    attr_reader :explain_scores,
                :es_score,
                :popularity,
                :query_length,
                :title,
                :description,
                :link,
                :public_timestamp,
                :format,
                :organisation,
                :indexable_content,
                :updated_at

    def get_org(organisation_content_ids)
      return 0 unless organisation_content_ids.present? && organisation_content_ids.any?

      organisation_enums[organisation_content_ids.first] || 0
    end

    def get_format(format)
      return 0 if format.nil? || format.empty?

      format_enums[format] || 0
    end

    def get_timestamp(timestamp)
      return 0 if timestamp.nil? || timestamp.empty?

      Date.parse(timestamp).to_time.to_i
    end

    def link_slash_count
      link.count("/")
    end

    def get_query_length(query)
      return 0 if query.nil?

      query.length
    end
  end
end
