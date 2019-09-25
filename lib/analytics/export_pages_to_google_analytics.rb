require "analytics/extract"
require "analytics/transform"
require "analytics/load"

module Analytics
  def self.export_pages_to_google_analytics
    data = Extract.new(ALL_CONTENT_SEARCH_INDICES)
    csv = Transform.to_csv(data)
    Load.upload_csv_to_google_analytics(csv)
  end
end
