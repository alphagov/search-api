module Analytics
  module Ga4Import
    class RelevanceReportGenerator
      def initialize
        @data_fetcher = DataFetcher.new
      end

      def call
        @data_fetcher.call
          .then { |paginated_data|
            PageViewConsolidator.new(paginated_data).consolidated_page_views
          }
          .then { |consolidated_page_views|
            ElasticSearchRelevancySerialiser.new(consolidated_page_views)
          }
          .relevance
          .to_json
      end
    end
  end
end
