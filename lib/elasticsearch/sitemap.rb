require "nokogiri"

EXCLUDED_FORMATS = ["recommended-link", "inside-government-link"]


class Sitemap
  def initialize(directory, timestamp = Time.now.utc)
    raise 'Sitemap directory is required' unless directory
    @directory = directory
    @timestamp = timestamp
  end

  def generate(all_indices)
    sitemap_writer = SitemapWriter.new(@directory, @timestamp)
    sitemap_filenames = sitemap_writer.write_sitemaps(all_indices)
    return write_index(sitemap_filenames)
  end

  def write_index(sitemap_filenames)
    index_filename = "sitemap_#{@timestamp.strftime('%FT%H%M%S')}.xml"
    index_full_path = File.join(@directory, index_filename)
    File.open(index_full_path, "w") do |sitemap_index_file|
      builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.sitemapindex(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
          sitemap_filenames.each do |sitemap_filename|
            xml.sitemap {
              xml.loc "#{base_url}#{"/"}#{sitemap_filename}"
              xml.lastmod @timestamp.strftime("%FT%T%:z")
            }
          end
        end
      end
      sitemap_index_file.write(builder.to_xml)
    end
    index_filename
  end

private
  def base_url
    return "https://www.gov.uk" if ENV["FACTER_govuk_platform"] == "production"
    "https://www.#{ENV["FACTER_govuk_platform"]}.alphagov.co.uk"
  end
end


class SitemapWriter
  def initialize(directory, timestamp)
    @directory = directory
    @timestamp = timestamp
    @sitemap_file_count = 0
  end

  def write_sitemaps(all_indices)
    sitemap_generator = SitemapGenerator.new(all_indices)
    # write our sitemap files and return an array of filenames
    sitemap_generator.sitemaps.map do |sitemap_xml|
      filename = next_filename
      File.open(File.join(@directory, filename), "w") do |file| 
        file.write(sitemap_xml)
      end
      filename
    end
  end

private
  def next_filename
    @sitemap_file_count += 1
    "sitemap_#{@sitemap_file_count}_#{@timestamp.strftime('%FT%H%M%S')}.xml"
  end
end


class SitemapGenerator
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
      yielder << "/"
      indices_for_sitemap = @sitemap_indices
      indices_for_sitemap.each do |index|
        index.all_document_links(EXCLUDED_FORMATS).each do |document|
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

  def generate_xml(chunk)
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
        chunk.each do |url|
          url = "#{base_url}#{url}" if url.start_with?("/")
          xml.url {
            xml.loc url
          }
        end
      end
    end
    builder.to_xml
  end

	private
    def base_url
      return "https://www.gov.uk" if ENV["FACTER_govuk_platform"] == "production"
      "https://www.#{ENV["FACTER_govuk_platform"]}.alphagov.co.uk"
    end
end