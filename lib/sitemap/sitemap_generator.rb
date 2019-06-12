class SitemapGenerator
  EXCLUDED_FORMATS = ["recommended-link"].freeze

  def initialize(search_config)
    @search_config = search_config
    @all_documents = get_all_documents
  end

  def self.sitemap_limit
    25_000
  end

  def get_all_documents
    search_body = {
      query: {
        bool: {
          must_not: { terms: { format: EXCLUDED_FORMATS } },
        }
      },
      post_filter: Search::FormatMigrator.new.call,
    }
    property_boost_calculator = PropertyBoostCalculator.new

    # We need the extra enumerator here so that we can inject the homepage
    # as the first item to be processed.
    Enumerator.new do |yielder|
      yielder << homepage

      enum = ScrollEnumerator.new(
        client: Services.elasticsearch(cluster: Clusters.default_cluster, timeout: SearchIndices::Index::TIMEOUT_SECONDS),
        search_body: search_body,
        index_names: index_names,
        batch_size: SearchIndices::Index.scroll_batch_size
      ) do |hit|
        SitemapPresenter.new(hit["_source"], property_boost_calculator)
      end

      enum.each { |doc| yielder << doc }
    end
  end

  def sitemaps
    @all_documents.each_slice(self.class.sitemap_limit).map do |chunk|
      generate_xml(chunk)
    end
  end

  # Generate a sitemap which matches the format specified in https://www.sitemaps.org/protocol.html
  def generate_xml(chunk)
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
        chunk.each do |document|
          xml.url {
            xml.loc document.url
            xml.lastmod document.last_updated if document.last_updated
            xml.priority document.priority
          }
        end
      end
    end

    builder.to_xml
  end

private

  StaticDocumentPresenter = Struct.new(:url, :last_updated, :priority)

  def index_names
    @search_config.content_index_names + [@search_config.govuk_index_name]
  end

  def homepage
    StaticDocumentPresenter.new(Plek.current.website_root + "/", nil, 0.5)
  end
end
