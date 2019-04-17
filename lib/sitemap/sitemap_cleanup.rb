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
    date_string = filename.match(/sitemap(?:_[0-9]+)?_([0-9T-]+)\.xml/)[1]
    Date.strptime(date_string, '%FT%H')
  end

  def sorted_unique_sitemap_dates
    all_sitemaps
      .reject { |sitemap| File.symlink?(sitemap) }
      .map { |sitemap| parse_sitemap_date(sitemap) }
      .uniq
      .sort
  end

  def sitemap_dates_to_delete
    @sitemap_dates_to_delete ||= sorted_unique_sitemap_dates[0...-days_to_keep]
  end

  def sitemap_linked_files
    @sitemap_linked_files ||=
      all_sitemaps
        .select { |sitemap| File.symlink?(sitemap) }
        .map { |sitemap| File.readlink(sitemap) }
  end

  def sitemap_files_to_delete
    all_sitemaps
      .reject { |sitemap| File.symlink?(sitemap) }
      .select { |sitemap| sitemap_dates_to_delete.include?(parse_sitemap_date(sitemap)) }
      .reject { |sitemap| sitemap_linked_files.include?(sitemap) }
  end
end
