module Sitemap
  class Generator
    def initialize(search_config, search_client, uploader, timestamp)
      @search_config    = search_config
      @search_client    = search_client
      @uploader         = uploader
      @timestamp        = timestamp
    end

    def run
      create_sitemap_index(create_sitemaps(batches_of_documents))
    end

    def create_sitemaps(enumerator)
      lazy_enum = enumerator.each_with_index.map do |documents, index|
        batch_number = index + 1
        create_sitemap(documents, batch_number)
      end
      lazy_enum.force
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

    def batches_of_documents
      Enumerator::Lazy.new(0...batch_total_count) do |yielder, index|
        yielder << [homepage] + get_documents_for_batch(index)
      end
    end

  private

    def get_documents_for_batch(batch_index)
      @search_client.search(
        index: index_names,
        body: batch_documents_query(batch_index),
      )["hits"]["hits"].map do |hit|
        SitemapPresenter.new(hit["_source"], property_boost_calculator)
      end
    end

    EXCLUDED_FORMATS = %w[recommended-link].freeze
    SITEMAP_LIMIT = 25_000
    SUB_DIRECTORY = "sitemaps".freeze

    StaticDocumentPresenter = Struct.new(:url, :last_updated, :priority)

    def index_names
      SearchConfig.content_index_names + [SearchConfig.govuk_index_name]
    end

    def homepage
      StaticDocumentPresenter.new(Plek.current.website_root + "/", nil, 0.5)
    end

    def batch_total_count
      @batch_total_count ||= document_count.fdiv(SITEMAP_LIMIT).ceil
    end

    def document_count
      query = {
        query: {
          bool: {
            must_not: { terms: { format: EXCLUDED_FORMATS } },
          },
        },
      }
      @search_client.count(body: query, index: index_names)["count"]
    end

    def batch_documents_query(batch_index)
      {
        from: batch_index * SITEMAP_LIMIT,
        size: SITEMAP_LIMIT,
        query: {
          bool: {
            must_not: { terms: { format: EXCLUDED_FORMATS } },
          },
        },
        post_filter: Search::FormatMigrator.new(@search_config).call,
      }
    end

    def property_boost_calculator
      PropertyBoostCalculator.new
    end

    def base_url
      Plek.current.website_root
    end
  end
end
