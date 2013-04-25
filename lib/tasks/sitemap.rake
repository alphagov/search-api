require "elasticsearch/sitemap"
EXCLUDED_FORMATS = ["recommended-link", "inside-government-link"]

namespace :sitemap do
  desc "Generate new sitemap files and if all is ok switch symlink"
  task :generate_and_replace do
    # Individual site maps can have a maximum of 50,000 links in them.
    # Generate site maps and then an index site map to point to them
    indices_for_sitemap = all_index_names.map do |index_name|
      search_server.index(index_name)
    end

    all_documents = Enumerator.new do |yielder|
      # Hard-code the site root, as it isn't listed in any search index
      yielder << "/"

      indices_for_sitemap.each do |index|
        index.all_document_links(EXCLUDED_FORMATS).each do |document|
          yielder << document
        end
      end
    end

    sitemap_directory = File.join(PROJECT_ROOT, "public", "system")
    sitemap = Sitemap.new(sitemap_directory)
    sitemap_index_filename = sitemap.generate(all_documents)

    sitemap_index_path = File.join(sitemap_directory, sitemap_index_filename)
    sitemap_link_path = File.join(sitemap_directory, "sitemap.xml")

    `ln -sf #{sitemap_index_path} #{sitemap_link_path}`
    fail("Symlinking failed") unless $?.success?
  end
end
