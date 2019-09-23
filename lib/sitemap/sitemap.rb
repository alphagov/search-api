class Sitemap
  SUB_DIRECTORY = "sitemaps".freeze

  def initialize(directory, timestamp = Time.now.utc)
    raise 'Sitemap directory is required' unless directory
    @output_path = File.join(directory, SUB_DIRECTORY)
    @directory = directory
    @timestamp = timestamp
  end

  def generate_and_replace(search_config)
    replace(generate(search_config))
  end

  def generate(search_config)
    FileUtils.mkdir_p(@output_path)

    sitemap_writer = SitemapWriter.new(@output_path, @timestamp)
    sitemaps = sitemap_writer.write_sitemaps(search_config)
    index = write_index(sitemaps.map(&:last))

    { sitemaps: sitemaps, index: index }
  end

  def replace(sitemaps:, index:)
    update_links(sitemaps)
    update_sitemap_link(index)
  end

  def update_links(sitemap_filenames)
    sitemap_filenames.each do |filename, link_filename|
      # use the absolute path here and not the linked path as the linked path
      # uses the release directory which is updated if more than 5 deployments
      # happen in a day
      output_path = File.symlink?(@output_path) ? File.readlink(@output_path) : @output_path

      tmpfile_name = "#{output_path}/#{link_filename}_tmp"
        # ensure the file has been deleted before starting as otherwise the process will crash
      File.delete(tmpfile_name) if File.exist?(tmpfile_name)
      # symlink creation is a create then move to ensure a symlink always exists:
      # http://blog.moertel.com/posts/2005-08-22-how-to-change-symlinks-atomically.html
      File.symlink("#{output_path}/#{filename}", tmpfile_name)
      FileUtils.mv(tmpfile_name, "#{output_path}/#{link_filename}")
    end
  end

  def update_sitemap_link(sitemap_filename)
    # symlink creation is a create then move to ensure a symlink always exists:
    # http://blog.moertel.com/posts/2005-08-22-how-to-change-symlinks-atomically.html
    File.symlink("#{@output_path}/#{sitemap_filename}", "#{@directory}/sitemap_tmp.xml")
    FileUtils.mv("#{@directory}/sitemap_tmp.xml", "#{@directory}/sitemap.xml")
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
