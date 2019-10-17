module Sitemap
  class Generator
    def initialize(search_config, uploader, timestamp)
      @search_config    = search_config
      @search_client    = Services.elasticsearch(hosts: search_config.base_uri, timeout: 10)
      @uploader         = uploader
      @timestamp        = timestamp
    end

    def run
      create_sitemap_index(create_sitemaps(get_all_documents))
    end

    def create_sitemaps(enumerator)
      enumerator.with_index.map do |documents, index|
        batch_number = index + 1
        documents.unshift(homepage) if batch_number == 1
        create_sitemap(documents, batch_number)
      end
    end

    def create_sitemap(documents, batch_number)
      file_name = "sitemap_#{batch_number}.xml"
      @uploader.upload(
        file_content: generate_sitemap_xml(documents),
        file_name:    file_name,
      )
      file_name
    end

    def create_sitemap_index(sitemaps)
      @uploader.upload(
        file_content: generate_sitemap_index_xml(sitemaps),
        file_name:    "sitemap.xml",
      )
    end

    # Generate a sitemap which matches the format specified in https://www.sitemaps.org/protocol.html
    def generate_sitemap_xml(documents)
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
          documents.each do |document|
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

    def generate_sitemap_index_xml(sitemap_filenames)
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.sitemapindex(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
          sitemap_filenames.each do |sitemap_filename|
            xml.sitemap {
              xml.loc "#{base_url}/#{SUB_DIRECTORY}/#{sitemap_filename}"
              xml.lastmod @timestamp.strftime("%FT%T%:z")
            }
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

      Enumerator::Lazy.new(0...total_page_count) do |yielder|
        if documents.count == SITEMAP_LIMIT
          sitemaps = documents.map do |document|
            SitemapPresenter.new(document["_source"], property_boost_calculator)
          end
          documents.clear
        end

        more_documents = scroll(scroll_id)

        if more_documents.any?
          documents.push(*more_documents)
        else
          sitemaps = documents.map do |document|
            SitemapPresenter.new(document["_source"], property_boost_calculator)
          end
        end

        yielder << sitemaps if sitemaps
      end
    end

    def initial_scroll
      @search_client.search(scroll_query)
    end

    def scroll(scroll_id)
      @search_client.scroll(scroll_id: scroll_id, scroll: "1m")["hits"]["hits"]
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
      PropertyBoostCalculator.new
    end

    def base_url
      Plek.current.website_root
    end
  end
end
