class SitemapGenerator
  def initialize(search_config, search_client, sitemap_writer, sitemap_uploader)
    @search_config = search_config
    @search_client = search_client
    @sitemap_writer = sitemap_writer
    @sitemap_uploader = sitemap_uploader
  end

  def run
    sitemap_files = create_sitemap_files(batches_of_documents)
    sitemap_index_file = create_sitemap_index_file(sitemap_files)

    { sitemaps: sitemap_files, index: sitemap_index_file }
  end

  def create_sitemap_files(enumerator)
    lazy_enum = enumerator.each_with_index.map do |documents, index|
      batch_number = index + 1
      sitemap_file = create_sitemap_file(documents, batch_number)
      upload_sitemap_file(sitemap_file)
      sitemap_file
    end
    lazy_enum.force
  end

  def create_sitemap_file(documents, batch_number)
    xml_content = generate_xml(documents)
    @sitemap_writer.write_sitemap(xml_content, batch_number)
  end

  def create_sitemap_index_file(sitemap_filenames)
    sitemap_index_file = @sitemap_writer.write_index(sitemap_filenames.map(&:last))

    source = "#{@sitemap_writer.output_path}/#{sitemap_index_file}"
    target = "sitemap.xml"

    @sitemap_uploader.upload(
      source,
      target,
    )
    sitemap_index_file
  end

  # Generate a sitemap which matches the format specified in https://www.sitemaps.org/protocol.html
  def generate_xml(documents)
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

  def all_documents_query
    {
      query: {
        bool: {
          must_not: { terms: { format: EXCLUDED_FORMATS } },
        },
      },
      post_filter: Search::FormatMigrator.new(@search_config).call,
    }
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

  def upload_sitemap_file(sitemap_file)
    filename      = "#{@sitemap_writer.output_path}/#{sitemap_file.first}"
    link_filename = "#{SitemapWriter::SUB_DIRECTORY}/#{sitemap_file.last}"

    @sitemap_uploader.upload(
      filename,
      link_filename,
    )
  end
end
