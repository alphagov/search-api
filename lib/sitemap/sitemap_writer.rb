class SitemapWriter
  SUB_DIRECTORY = "sitemaps".freeze

  attr_reader :output_path

  def initialize(directory, timestamp)
    @output_path = File.join(directory, SUB_DIRECTORY)
    @timestamp = timestamp
  end

  def write_sitemap(content, batch_number)
    filename = filename(batch_number)
    link_filename = link_filename(batch_number)

    File.open(File.join(@output_path, filename), "w") do |file|
      file.write(content)
    end

    [filename, link_filename]
  end

  def write_index(sitemap_filenames)
    index_filename = "sitemap_#{@timestamp.strftime('%FT%H')}.xml"
    index_full_path = File.join(@output_path, index_filename)

    File.open(index_full_path, "w") do |sitemap_index_file|
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
      sitemap_index_file.write(builder.to_xml)
    end
    index_filename
  end

private

  def filename(batch_number)
    "sitemap_#{batch_number}_#{@timestamp.strftime('%FT%H')}.xml"
  end

  def link_filename(batch_number)
    "sitemap_#{batch_number}.xml"
  end

  def base_url
    Plek.current.website_root
  end
end
