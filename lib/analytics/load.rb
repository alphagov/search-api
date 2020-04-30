require "analytics/load_service"

module Analytics
  class Load
    def self.upload_csv_to_google_analytics(csv)
      loader = LoadService.new
      loader.delete_previous_uploads
      loader.upload_csv(csv)
    rescue StandardError => e
      puts "The export has failed with the following error: #{e.message}"
    end
  end
end
