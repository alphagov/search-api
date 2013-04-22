require "nokogiri"

EXCLUDED_FORMATS = ["recommended-link", "inside-government-link"]

def base_url
  return "https://www.gov.uk" if ENV["FACTER_govuk_platform"] == "production"
  "https://www.#{ENV["FACTER_govuk_platform"]}.alphagov.co.uk"
end

SITEMAP_LIMIT = 50_000

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

    sitemap_file_count = 1
    sitemap_timestamp = Time.now.utc.strftime("%FT%H%M%S")
    sitemap_timestamp_with_timezone = Time.now.utc.strftime("%FT%T%:z")
    sitemap_filenames = []

    all_documents.each_slice(SITEMAP_LIMIT) do |chunk|
      filename = "sitemap_#{sitemap_file_count}_#{sitemap_timestamp}.xml"
      sitemap_filenames << filename 
      File.open(File.join(PROJECT_ROOT, "public", filename), "w") do |sitemap_file|
        builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
            xml.url {
              xml.loc "#{base_url}#{"/"}"
            }
            chunk.each do |document|
              unless EXCLUDED_FORMATS.include?(document.format)
                url = document.link
                url = "#{base_url}#{url}" if url =~ /^\//
                xml.url {
                  xml.loc url
                }
              end
            end
          end
        end
        sitemap_file.write(builder.to_xml)
      end

      sitemap_file_count += 1
    end

    File.open(File.join(PROJECT_ROOT, "public", "sitemap_#{sitemap_timestamp}.xml"), "w") do |sitemap_index_file|
      builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.sitemapindex(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
          sitemap_filenames.each do |sitemap_filename|
            xml.sitemap {
              xml.loc "#{base_url}#{"/"}#{sitemap_filename}"
              xml.lastmod "#{sitemap_timestamp_with_timezone}"
            }
          end
        end
      end
      sitemap_index_file.write(builder.to_xml)
    end

  end
end
