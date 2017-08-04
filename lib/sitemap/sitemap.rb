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
    write_index(sitemap_filenames)
  end

  def write_index(sitemap_filenames)
    index_filename = "sitemap_#{@timestamp.strftime('%FT%H')}.xml"
    index_full_path = File.join(@output_path, index_filename)
    File.open(index_full_path, "w") do |sitemap_index_file|
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.sitemapindex(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
          sitemap_filenames.each do |sitemap_filename|
            xml.sitemap {
              xml.loc "#{base_url}/#{@subdirectory}/#{sitemap_filename}"
              xml.lastmod @timestamp.strftime("%FT%T%:z")
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
