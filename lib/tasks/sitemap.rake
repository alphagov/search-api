require "aws-sdk-s3"
require "sitemap/sitemap"
require "tmpdir"
require "s3_client"

namespace :sitemap do
  desc "Generate new sitemap files and if all is ok switch symlink"
  task :generate_and_replace do
    # Individual site maps can have a maximum of 50,000 links in them.
    # Generate site maps and then an index site map to point to them

    output_directory = File.join(PROJECT_ROOT, "public")

    search_client = Services.elasticsearch(
      cluster: Clusters.default_cluster,
      timeout: 10,
    )

    generator = SitemapGenerator.new(
      SearchConfig.default_instance,
      search_client,
      SitemapWriter.new(output_directory, Time.now.utc),
      S3Client.new(@bucket_name),
    )

    sitemap = Sitemap.new(generator, output_directory)

    sitemap.generate_and_replace
    sitemap.cleanup
  end

  desc "Generate new sitemap files and upload to S3"
  task :generate_and_upload do
    @bucket_name = ENV["AWS_S3_BUCKET_NAME"]
    raise "Missing required AWS_S3_BUCKET_NAME" if @bucket_name.nil?

    search_client = Services.elasticsearch(
      cluster: Clusters.default_cluster,
      timeout: 10,
    )

    Dir.mktmpdir do |output_directory|
      generator = SitemapGenerator.new(
        SearchConfig.default_instance,
        search_client,
        SitemapWriter.new(output_directory, Time.now.utc),
        S3Client.new(@bucket_name),
      )

      Sitemap.new(generator, output_directory).generate
    end
  end
end
