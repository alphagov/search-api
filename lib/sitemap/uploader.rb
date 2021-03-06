module Sitemap
  class Uploader
    def initialize(bucket_name)
      @bucket_name = bucket_name
      @logger      = Logging.logger[self]
    end

    def upload(file_content:, file_name:)
      @logger.info "Uploading #{file_name} ..."
      o = Aws::S3::Object.new(bucket_name: @bucket_name, key: file_name)
      raise "Failed to create sitemap file '#{file_name}'" unless o.put(body: file_content)
    end
  end
end
