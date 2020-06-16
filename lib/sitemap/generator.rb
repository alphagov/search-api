module Sitemap
  class Generator
    def initialize(search_config, uploader, timestamp)
      @search_config = search_config
      @search_client = Services.elasticsearch(hosts: search_config.base_uri, timeout: 10)
      @uploader      = uploader
      @timestamp     = timestamp
      @logger        = Logging.logger[self]
    end

    def run
      create_sitemap_index(create_sitemaps(get_all_documents))
    end

    def create_sitemaps(enumerator)
      enumerator.with_index.map do |documents, index|
        batch_number = index + 1
        create_sitemap(documents, batch_number)
      end
    end

    def create_sitemap(documents, batch_number)
      @logger.info "Creating sitemap #{batch_number} ..."
      file_name = "sitemap_#{batch_number}.xml"
      @uploader.upload(
        file_content: generate_sitemap_xml(documents),
        file_name: file_name,
      )
      file_name
    end

    def create_sitemap_index(sitemaps)
      @logger.info "Creating sitemap index ..."
      @uploader.upload(
        file_content: generate_sitemap_index_xml(sitemaps),
        file_name: "sitemap.xml",
      )
    end

    # Generate a sitemap which matches the format specified in https://www.sitemaps.org/protocol.html
    def generate_sitemap_xml(documents)
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
          documents.each do |document|
            xml.url do
              xml.loc document.url
              xml.lastmod document.last_updated if document.last_updated
              xml.priority document.priority
            end
          end
        end
      end
      builder.to_xml
    end

    def generate_sitemap_index_xml(sitemap_filenames)
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.sitemapindex(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
          sitemap_filenames.each do |sitemap_filename|
            xml.sitemap do
              xml.loc "#{base_url}/#{SUB_DIRECTORY}/#{sitemap_filename}"
              xml.lastmod @timestamp.strftime("%FT%T%:z")
            end
          end
        end
      end
      builder.to_xml
    end

  private

    def get_all_documents
      page                  = initial_scroll
      scroll_id             = page["_scroll_id"]
      documents             = page["hits"]["hits"]
      total_documents_count = page["hits"]["total"]
      total_page_count      = total_documents_count.fdiv(SCROLL_BATCH_SIZE).ceil
      chunk                 = [homepage]

      Enumerator::Lazy.new(0..total_page_count) do |yielder|
        next if documents.empty? && chunk.empty?

        documents.map do |document|
          chunk << SitemapPresenter.new(document["_source"], property_boost_calculator)

          parts = document["_source"]["parts"] || []

          parts.each do |part|
            part_document = document["_source"].merge(
              "is_part" => true,
              "link" => document["_source"]["link"] + "/" + part["slug"],
            )

            chunk << SitemapPresenter.new(part_document, property_boost_calculator)

            if chunk.size >= SITEMAP_LIMIT
              yielder << chunk
              chunk = []
            end
          end

          if chunk.size >= SITEMAP_LIMIT
            yielder << chunk
            chunk = []
          end
        end

        page      = scroll(scroll_id)
        documents = page["hits"]["hits"]
        scroll_id = page.fetch("_scroll_id")

        if documents.empty?
          yielder << chunk unless chunk.empty?
          chunk = []
        end
      end
    end

    def initial_scroll
      @search_client.search(scroll_query)
    end

    def scroll(scroll_id)
      @search_client.scroll(scroll_id: scroll_id, scroll: "1m")
    end

    def scroll_query
      {
        body: all_documents_query,
        index: index_names,
        scroll: "1m",
        size: SCROLL_BATCH_SIZE,
        search_type: "query_then_fetch",
        version: true,
      }
    end

    def all_documents_query
      {
        query: {
          bool: {
            must_not: { terms: { format: EXCLUDED_FORMATS } },
          },
        },
        post_filter: Search::FormatMigrator.new(@search_config).call,
        sort: %w[_doc],
      }
    end

    EXCLUDED_FORMATS = %w[recommended-link].freeze
    SITEMAP_LIMIT = 25_000
    SCROLL_BATCH_SIZE = 1000
    SUB_DIRECTORY = "sitemaps".freeze

    def index_names
      SearchConfig.content_index_names + [SearchConfig.govuk_index_name]
    end

    StaticDocumentPresenter = Struct.new(:url, :last_updated, :priority)

    def homepage
      StaticDocumentPresenter.new(Plek.current.website_root + "/", nil, 0.5)
    end

    def property_boost_calculator
      @property_boost_calculator ||= PropertyBoostCalculator.new
    end

    def base_url
      Plek.current.website_root
    end
  end
end
