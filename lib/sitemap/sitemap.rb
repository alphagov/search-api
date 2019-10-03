class Sitemap
  def initialize(sitemap_generator, directory)
    @sitemap_generator = sitemap_generator
    @output_path = File.join(directory, SitemapWriter::SUB_DIRECTORY)
    @directory = directory
  end

  def generate_and_replace
    replace(generate)
  end

  def generate
    create_output_directory
    @sitemap_generator.run
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

  def cleanup
    sitemap_cleanup = SitemapCleanup.new(@output_path)
    sitemap_cleanup.delete_excess_sitemaps
  end

  def create_output_directory
    return if File.directory?(@output_path)

    FileUtils.mkdir_p(@output_path)
  end
end
