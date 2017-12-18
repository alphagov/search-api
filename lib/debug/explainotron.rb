require 'rainbow'

module Debug
  class Explainotron
    def self.explain!(query)
      client = Services.elasticsearch

      parsed_params = {
        query: query,
        debug: { explain: true, disable_best_bets: true, disable_popularity: true, disable_boosting: true }
 }
      search_params = Search::QueryParameters.new(parsed_params)

      query_builder = Search::QueryBuilder.new(
        search_params: search_params,
        content_index_names: SearchConfig.instance.content_index_names,
        metasearch_index: SearchConfig.instance.metasearch_index
      )
      search_query = query_builder.payload

      client.search(
        index: "govuk,mainstream,detailed,government",
        analyzer: 'with_search_synonyms',
        body: search_query.merge(size: 3)
      )["hits"]["hits"]
    end

    def self.print(explain_output, query, indent: 0)
      details = explain_output["details"]
      value = explain_output["value"]
      description = explain_output["description"]

      description.gsub!(/[0-9.]+/) do |match|
        Rainbow(match).cyan
      end

      description.gsub!(/(?<=:)(.*)(?= in)/) do |match|
        Rainbow(match).green
      end

      spaces = ' ' * indent
      puts spaces.to_s + Rainbow("[#{value}] ").magenta + description

      if details
        details.each do |detail|
          print(detail, query, indent: indent + 2)
        end
      end
    end
  end
end
