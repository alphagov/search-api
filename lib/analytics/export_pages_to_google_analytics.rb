require "analytics/extract"
require "analytics/transform"
require "analytics/load"

module Analytics
  def self.export_pages_to_google_analytics
    all_content_search_indices = %w[government govuk].freeze
    data = Extract.new(all_content_search_indices)
    csv = Transform.to_csv(data)
    Load.upload_csv_to_google_analytics(csv)
  end
end
