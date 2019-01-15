class AnalyticsData
  def initialize(elasticsearch_url, indices)
    @elasticsearch_url = elasticsearch_url
    @indices = indices
  end

  def headers
    columns.keys
  end

  def rows
    client = Elasticsearch::Client.new(host: @elasticsearch_url)

    query = {
      query: {
        bool: {
          must: { match_all: {} },
          filter: Search::FormatMigrator.new.call,
        },
      },
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
      "ga:productSku" => lambda { |item| item["content_id"] || item["link"] },
      "ga:productName" => lambda { |item| item["link"] },
      "ga:productBrand" => lambda { |item| item["primary_publishing_organisation"]&.first },
      "ga:productCategoryHierarchy" => lambda { |_| nil }, # Placeholder: taxonomy
      "ga:dimension72" => lambda { |item| sanitise_for_google_analytics(item["title"]) },
      "ga:dimension73" => lambda { |item| item["content_store_document_type"] || item["format"] },
      "ga:dimension74" => lambda { |item| item["navigation_document_supertype"] },
      "ga:dimension75" => lambda { |_| nil }, # Placeholder: mainstream/specialist supertype
      "ga:dimension76" => lambda { |item| item["user_journey_document_supertype"] },
      "ga:dimension77" => lambda { |item| item["organisations"]&.join(", ") },
      "ga:dimension78" => lambda { |item| item["public_timestamp"].nil? ? nil : Date.parse(item["public_timestamp"]).strftime("%Y%m%d") },
      "ga:dimension79" => lambda { |_| nil }, # Placeholder: purpose not yet decided
      "ga:dimension80" => lambda { |_| nil }, # Placeholder: is page a best bet?
    }
  end

  def sanitise_for_google_analytics(data)
    data
      &.gsub(/\r?\n/, " ")
      &.strip
  end
end
