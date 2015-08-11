require "nokogiri"
require 'plek'

EXCLUDED_FORMATS = ["recommended-link", "inside-government-link"]


class Sitemap
  def initialize(directory, timestamp = Time.now.utc)
    raise 'Sitemap directory is required' unless directory
    @subdirectory = "sitemaps"
    @output_path = File.join(directory, @subdirectory)
    @timestamp = timestamp
  end

  def generate(content_indices)
    FileUtils.mkdir_p(@output_path)
    sitemap_writer = SitemapWriter.new(@output_path, @timestamp)
    sitemap_filenames = sitemap_writer.write_sitemaps(content_indices)
    return write_index(sitemap_filenames)
  end

  def write_index(sitemap_filenames)
    index_filename = "sitemap_#{@timestamp.strftime('%FT%H')}.xml"
    index_full_path = File.join(@output_path, index_filename)
    File.open(index_full_path, "w") do |sitemap_index_file|
      builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.sitemapindex(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
          sitemap_filenames.each do |sitemap_filename|
            xml.sitemap {
              xml.loc "#{base_url}/#{@subdirectory}/#{sitemap_filename}"
              # Ideally want to use %:z to indicate timezone, however, due to difference
              # in ruby versions 1.9.3 and 1.9.2, production uses 1.9.2
              # so we need to use Z, instead.
              xml.lastmod @timestamp.strftime("%FT%TZ")
            }
          end
        end
      end
      sitemap_index_file.write(builder.to_xml)
    end
    index_full_path
  end

  def cleanup
    sitemap_cleanup = SitemapCleanup.new(@output_path)
    sitemap_cleanup.delete_excess_sitemaps
  end

private
  def base_url
    Plek.current.website_root
  end
end


class SitemapWriter
  def initialize(directory, timestamp)
    @directory = directory
    @timestamp = timestamp
    @sitemap_file_count = 0
  end

  def write_sitemaps(content_indices)
    sitemap_generator = SitemapGenerator.new(content_indices)
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
    "sitemap_#{@sitemap_file_count}_#{@timestamp.strftime('%FT%H')}.xml"
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

      @sitemap_indices.each do |index|
        index.all_document_links(EXCLUDED_FORMATS).each do |document|
          if document
            yielder << document
          end
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
          url = Array(url).first
          url = URI.join(base_url, url) unless url.start_with?("http")
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
    Plek.current.website_root
  end
end

class SitemapCleanup
  def initialize(directory)
    @directory = directory
    @days_to_keep = 4
  end

  def delete_excess_sitemaps
    sitemap_files_to_delete.each do |filename|
      FileUtils.rm(filename)
    end
  end

private
  attr_reader :directory, :days_to_keep

  def all_sitemaps
    @all_sitemaps ||= Dir.glob("#{directory}/*.xml")
  end

  def parse_sitemap_date(filename)
    date_string = filename.match(/sitemap(?:_[0-9])?_([0-9T-]+)\.xml/)[1]
    Date.strptime(date_string, '%FT%H')
  end

  def sorted_unique_sitemap_dates
    all_sitemaps.map { |sitemap|
      parse_sitemap_date(sitemap)
    }.uniq.sort
  end

  def sitemap_dates_to_delete
    @sitemap_dates_to_delete ||= sorted_unique_sitemap_dates[0...-days_to_keep]
  end

  def sitemap_files_to_delete
    all_sitemaps.select do |sitemap|
      sitemap_dates_to_delete.include?(parse_sitemap_date(sitemap))
    end
  end
end

