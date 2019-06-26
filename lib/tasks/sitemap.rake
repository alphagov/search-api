require "sitemap/sitemap"

namespace :sitemap do
  desc "Generate new sitemap files and if all is ok switch symlink"
  task :generate_and_replace do
    # Individual site maps can have a maximum of 50,000 links in them.
    # Generate site maps and then an index site map to point to them

    output_directory = File.join(PROJECT_ROOT, "public")
    sitemap = Sitemap.new(output_directory)
    sitemap.generate(SearchConfig.default_instance)

    sitemap.cleanup
  end
end
