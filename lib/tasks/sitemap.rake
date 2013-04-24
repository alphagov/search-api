require "elasticsearch/sitemap"

namespace :sitemap do
  desc "Generate new sitemap files and if all is ok switch symlink"
  task :generate_and_replace do
    # Individual site maps can have a maximum of 50,000 links in them.
    # Generate site maps and then an index site map to point to them
    indices_for_sitemap = all_index_names.map do |index_name|
      search_server.index(index_name)
    end

    all_documents = indices_for_sitemap.flat_map do |index|
      index.all_documents.to_a
    end

    sitemap_directory = File.join(PROJECT_ROOT, "public")
    sitemap = Sitemap.new(sitemap_directory)
    sitemap_index_filename = sitemap.generate(all_documents)

    sitemap_index_path = File.join(sitemap_directory, sitemap_index_filename)
    sitemap_link_path = File.join(sitemap_directory, "sitemap.xml")

    `ln -sf #{sitemap_index_path} #{sitemap_link_path}`
    fail("Symlinking failed") unless $?.success?
  end
end
