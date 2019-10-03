class SitemapWriter
  def initialize(directory, timestamp)
    @directory = directory
    @timestamp = timestamp
    @sitemap_file_count = 0
  end

  def write_sitemaps(search_config)
    sitemap_generator = SitemapGenerator.new(search_config)
    # write our sitemap files and return an array of filenames
    sitemap_generator.sitemap_chunks.map do |chunk|
      filename, link_filename = next_filename
      File.open(File.join(@directory, filename), "w") do |file|
        sitemap_xml = sitemap_generator.generate_xml(chunk)
        file.write(sitemap_xml)
      end
      [filename, link_filename]
    end
  end

private

  def next_filename
    @sitemap_file_count += 1
    [
      "sitemap_#{@sitemap_file_count}_#{@timestamp.strftime('%FT%H')}.xml",
      "sitemap_#{@sitemap_file_count}.xml",
    ]
  end
end
