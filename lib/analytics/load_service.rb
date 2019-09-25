require "google/apis/analytics_v3"
require "googleauth"
require "analytics/google_analytics_export_credentials"

module Analytics
  class LoadService
    include Google::Apis::AnalyticsV3
    include Google::Auth

    SCOPES = ["https://www.googleapis.com/auth/analytics.edit"].freeze

    attr_reader :service

    def initialize
      @service = AnalyticsService.new # Google::Apis::AnalyticsV3::AnalyticsService
      @service.authorization = GoogleAnalyticsExportCredentials.authorization(SCOPES)
    end

    def upload_csv(csv_data)
      assert_has_required_env_vars

      response = ""
      Tempfile.create(["search_api_indexed_pages", ".csv"], export_path) do |file|
        file.write(csv_data)
        response = service.upload_data(
          ENV["GOOGLE_EXPORT_ACCOUNT_ID"],
          ENV["GOOGLE_EXPORT_WEB_PROPERTY_ID"],
          ENV["GOOGLE_EXPORT_CUSTOM_DATA_SOURCE_ID"],
          fields: "accountId,customDataSourceId,errors,id,kind,status,uploadTime",
          upload_source: file.path,
          content_type: "application/octet-stream",
        )
      end
      response
    end

    def delete_previous_uploads
      assert_has_required_env_vars

      upload_list = service.list_uploads(
        ENV["GOOGLE_EXPORT_ACCOUNT_ID"],
        ENV["GOOGLE_EXPORT_WEB_PROPERTY_ID"],
        ENV["GOOGLE_EXPORT_CUSTOM_DATA_SOURCE_ID"],
      )

      return unless upload_list.items.count.positive?

      old_file_ids = upload_list.items.map(&:id)

      delete_upload_data_request_object = Google::Apis::AnalyticsV3::DeleteUploadDataRequest.new(custom_data_import_uids: old_file_ids)

      service.delete_upload_data(
        ENV["GOOGLE_EXPORT_ACCOUNT_ID"],
        ENV["GOOGLE_EXPORT_WEB_PROPERTY_ID"],
        ENV["GOOGLE_EXPORT_CUSTOM_DATA_SOURCE_ID"],
        delete_upload_data_request_object,
      )
    end

  private

    REQUIRED_ENV_VARS = %w(
      GOOGLE_PRIVATE_KEY
      GOOGLE_CLIENT_EMAIL
      GOOGLE_EXPORT_ACCOUNT_ID
      GOOGLE_EXPORT_WEB_PROPERTY_ID
      GOOGLE_EXPORT_CUSTOM_DATA_SOURCE_ID
    ).freeze

    def assert_has_required_env_vars
      return unless missing_env_vars.any?

      raise ArgumentError, "Required environment variables #{missing_env_vars.to_sentence} are unset."
    end

    def missing_env_vars
      REQUIRED_ENV_VARS.select { |var| ENV[var].nil? }
    end

    def export_path
      ENV["EXPORT_PATH"] || Dir.pwd
    end
  end
end
