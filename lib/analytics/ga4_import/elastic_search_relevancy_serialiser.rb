module Analytics
  module Ga4Import
    class ElasticSearchRelevancySerialiser
      def initialize(consolidated_data)
        @consolidated_data = consolidated_data
      end

      def relevance
        consolidated_data.flat_map.with_index(1) do |(base_path, page_views), index|
          [
            elastic_search_index(base_path).to_json,
            elastic_search_rank(base_path, index, page_views).to_json,
          ]
        end
      end

    private

      attr_reader :consolidated_data

      def elastic_search_index(base_path)
        {
          index: {
            _type: "page-traffic",
            _id: base_path,
          },
        }
      end

      def elastic_search_rank(base_path, index, page_views)
        {
          path_components: path_components(base_path),
          rank_14: index,
          vc_14: page_views,
          vf_14: page_views / total_page_views.to_f,
        }
      end

      def path_components(path)
        result = []

        components = path.sub("/", "").split("/")
        (1..components.length).each do |i|
          result.append("/#{components.first(i).join('/')}")
        end
        result
      end

      def total_page_views
        @total_page_views ||= consolidated_data.values.reduce(:+)
      end
    end
  end
end
