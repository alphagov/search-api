class Sitemap
  SUB_DIRECTORY = "sitemaps".freeze

  def initialize(directory, timestamp = Time.now.utc)
    raise 'Sitemap directory is required' unless directory
    @output_path = File.join(directory, SUB_DIRECTORY)
    @directory = directory
    @timestamp = timestamp
  end

  def generate(content_indices)
    FileUtils.mkdir_p(@output_path)

    # generate and link the sitemap data files
    sitemap_writer = SitemapWriter.new(@output_path, @timestamp)
    sitemap_filenames_with_linkname = sitemap_writer.write_sitemaps(content_indices)
    update_links(sitemap_filenames_with_linkname)

    # generate and link the sitemap index file
    sitemap_link_names = sitemap_filenames_with_linkname.map(&:last)
    index_filename = write_index(sitemap_link_names)
    update_sitemap_link(index_filename)
  end

  def update_links(sitemap_filenames)
    sitemap_filenames.each do |filename, link_filename|
      File.symlink("#{@output_path}/#{filename}", "#{@output_path}/#{link_filename}")
    end
  end

  def update_sitemap_link(sitemap_filename)
    File.symlink("#{@output_path}/#{sitemap_filename}", "#{@directory}/sitemap.xml")
  end

  def write_index(sitemap_filenames)
    index_filename = "sitemap_#{@timestamp.strftime('%FT%H')}.xml"
    index_full_path = File.join(@output_path, index_filename)
    File.open(index_full_path, "w") do |sitemap_index_file|
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.sitemapindex(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
          sitemap_filenames.each do |sitemap_filename|
            xml.sitemap {
              xml.loc "#{base_url}/#{SUB_DIRECTORY}/#{sitemap_filename}"
              xml.lastmod @timestamp.strftime("%FT%T%:z")
            }
          end
        end
      end
      sitemap_index_file.write(builder.to_xml)
    end
    index_filename
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
