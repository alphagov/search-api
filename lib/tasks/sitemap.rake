require "aws-sdk-s3"
require "tmpdir"
require "sitemap/uploader"

namespace :sitemap do
  desc "Generate new sitemap files and upload to S3"
  task :generate_and_upload do
    @bucket_name = ENV["AWS_S3_BUCKET_NAME"]
    raise "Missing required AWS_S3_BUCKET_NAME" if @bucket_name.nil?

    search_client = Services.elasticsearch(
      cluster: Clusters.default_cluster,
      timeout: 10,
    )

    Dir.mktmpdir do |output_directory|
      SitemapGenerator.new(
        SearchConfig.default_instance,
        search_client,
        Sitemap::Writer.new(output_directory, Time.now.utc),
        Sitemap::Uploader.new(@bucket_name),
      ).run
    end
  end
end
