require "aws-sdk-s3"

namespace :page_traffic do
  desc "Bulk load data from Google Analytics"
  task :load, :environment do
    # This task will now start the process of generating the data from Google Analytics and sending it to GovukIndex::PageTrafficLoader for processing

    logger.info "Processing Ga4 Analytics..."

    # report = Analytics::Ga4Import::RelevanceReportGenerator.new.call

    file = File.read('page-traffic.json')

    logger.info "Finished processing Ga4 Analytics..."

    Clusters.active.each do |cluster|
      logger.info "Performing page traffic load for cluster #{cluster.key}..."
      GovukIndex::PageTrafficLoader.new(cluster:).load_from(file)
    end
  end
end
