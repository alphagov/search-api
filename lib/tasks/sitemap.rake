require "aws-sdk-s3"
require "sitemap/sitemap"
require "tmpdir"

namespace :sitemap do
  desc "Generate new sitemap files and if all is ok switch symlink"
  task :generate_and_replace do
    # Individual site maps can have a maximum of 50,000 links in them.
    # Generate site maps and then an index site map to point to them

    output_directory = File.join(PROJECT_ROOT, "public")
    sitemap = Sitemap.new(output_directory)
    sitemap.generate_and_replace(SearchConfig.default_instance)

    sitemap.cleanup
  end

  desc "Generate new sitemap files and upload to S3"
  task :generate_and_upload do
    @bucket_name = ENV["AWS_S3_BUCKET_NAME"]
    raise "Missing required AWS_S3_BUCKET_NAME" if @bucket_name.nil?

    puts "Generating sitemaps..."

    Dir.mktmpdir do |output_directory|
      filenames = Sitemap.new(output_directory).generate(SearchConfig.default_instance)

      puts "Uploading sitemaps..."

      filenames[:sitemaps].each do |filename, link_filename|
        upload_to_s3(
          "#{output_directory}/#{Sitemap::SUB_DIRECTORY}/#{filename}",
          "#{Sitemap::SUB_DIRECTORY}/#{link_filename}",
        )
      end

      upload_to_s3(
        "#{output_directory}/#{Sitemap::SUB_DIRECTORY}/#{filenames[:index]}",
        "sitemap.xml",
      )
    end
  end

  def upload_to_s3(source, target)
    o = Aws::S3::Object.new(bucket_name: @bucket_name, key: target)
    raise "Failed to upload sitemap file '#{source}' as '#{target}'" unless o.upload_file(source)
  end
end
