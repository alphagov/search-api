module Analytics
  class Extract
    def initialize(indices)
      @indices = indices
    end

    def headers
      columns.keys
    end

    def rows
      client = Elasticsearch::Client.new(host: Clusters.default_cluster.uri)

      query = {
        query: {
          bool: {
            must: { match_all: {} },
          },
        },
        post_filter: Search::FormatMigrator.new(SearchConfig.default_instance).call,
      }

      ScrollEnumerator.new(client: client, index_names: @indices, search_body: query) do |hit|
        item = hit["_source"]

        columns.values.map { |i| i.call(item) }
      end
    end

  private

    def columns
      # See https://gov-uk.atlassian.net/wiki/display/GOVUK/Analytics+on+GOV.UK
      # for further details on the purpose of each dimension.
      @columns ||= {
        "ga:productSku" => ->(item) { item["content_id"] || item["link"] },
        "ga:productName" => ->(item) { item["link"] },
        "ga:productBrand" => ->(item) { item["primary_publishing_organisation"]&.first },
        "ga:productCategoryHierarchy" => ->(_) { nil }, # Placeholder: taxonomy
        "ga:dimension72" => ->(item) { sanitise_for_google_analytics(item["title"]) },
        "ga:dimension73" => ->(item) { item["content_store_document_type"] || item["format"] },
        "ga:dimension74" => ->(_) { nil }, # Placeholder: was navigation_document_supertype
        "ga:dimension75" => ->(_) { nil }, # Placeholder: mainstream/specialist supertype
        "ga:dimension76" => ->(item) { item["user_journey_document_supertype"] },
        "ga:dimension77" => ->(item) { item["organisations"]&.join(", ") },
        "ga:dimension78" => ->(item) { item["public_timestamp"].nil? ? nil : Date.parse(item["public_timestamp"]).strftime("%Y%m%d") },
        "ga:dimension79" => ->(_) { nil }, # Placeholder: purpose not yet decided
        "ga:dimension80" => ->(_) { nil }, # Placeholder: is page a best bet?
      }
    end

    def sanitise_for_google_analytics(data)
      data
        &.gsub(/\r?\n/, " ")
        &.strip
    end
  end
end
