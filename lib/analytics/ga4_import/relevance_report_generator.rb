module Analytics
  module Ga4Import
    class RelevanceReportGenerator
      def self.call
        new.call
      end

      def call
        google_analytics_service = Analytics::Ga4Import::DataFetcher.new
        paginated_data = google_analytics_service.call
        consolidated_page_views = Analytics::Ga4Import::PageViewConsolidator.new(paginated_data).consolidated_page_views
        elastic_search_relevancy_serialiser = Analytics::Ga4Import::ElasticSearchRelevancySerialiser.new(consolidated_page_views)
        relevancy = elastic_search_relevancy_serialiser.relevance
        relevancy.to_s
      end
    end
  end
end
