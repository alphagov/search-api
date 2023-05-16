require "aws-sdk-s3"

namespace :page_traffic do
  desc "Bulk load data from Google Analytics"
  task :load, :environment do
    s3 = Aws::S3::Client.new

    puts "Downloading file from S3..."
    resp = s3.get_object(bucket: ENV["AWS_SEARCH_ANALYTICS_BUCKET"], key: "page-traffic.dump")

    Clusters.active.each do |cluster|
      puts "Performing page traffic load for cluster #{cluster.key}..."
      resp.body.rewind
      GovukIndex::PageTrafficLoader.new(cluster:).load_from(resp.body)
    end
  end
end
