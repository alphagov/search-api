class S3Client
  def initialize(bucket_name)
    @bucket_name = bucket_name
  end

  def upload(source, target)
    o = Aws::S3::Object.new(bucket_name: @bucket_name, key: target)
    raise "Failed to upload sitemap file '#{source}' as '#{target}'" unless o.upload_file(source)
  end
end
