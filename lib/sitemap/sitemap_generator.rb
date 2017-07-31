class SitemapGenerator
  EXCLUDED_FORMATS = ["recommended-link", "inside-government-link"].freeze

  def initialize(sitemap_indices)
    @sitemap_indices = sitemap_indices
    @all_documents = get_all_documents
  end

  def self.sitemap_limit
    50_000
  end

  def get_all_documents
    Enumerator.new do |yielder|
      # Hard-code the site root, as it isn't listed in any search index
      yielder << homepage_document

      @sitemap_indices.each do |index|
        index.all_documents(exclude_formats: EXCLUDED_FORMATS).each do |document|
          yielder << document
        end
      end
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
          sitemap_presenter = SitemapPresenter.new(document)

          xml.url {
            xml.loc sitemap_presenter.url
            xml.lastmod sitemap_presenter.last_updated if sitemap_presenter.last_updated
            xml.priority sitemap_presenter.priority
          }
        end
      end
    end

    builder.to_xml
  end

private

  StaticDocument = Struct.new(:link, :public_timestamp, :is_withdrawn)

  def homepage_document
    StaticDocument.new("/", nil, false)
  end
end
