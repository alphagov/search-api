require "google/apis/analyticsreporting_v4"
require "googleauth"
require "analytics/google_analytics_export_credentials"

module Analytics
  module ReportRequester
    include Google::Apis::AnalyticsreportingV4
    include Google::Auth

    SCOPES = [AUTH_ANALYTICS].freeze

    REQUIRED_ENV_VARS = %w(
      GOOGLE_PRIVATE_KEY
      GOOGLE_CLIENT_EMAIL
      GOOGLE_ANALYTICS_GOVUK_VIEW_ID
    ).freeze

    def authenticated_service
      assert_has_required_env_vars

      service = AnalyticsReportingService.new
      service.authorization = GoogleAnalyticsExportCredentials.authorization(SCOPES)
      service
    end

    def assert_has_required_env_vars
      return unless missing_env_vars.any?

      raise ArgumentError, "Required environment variables #{missing_env_vars.to_sentence} are unset."
    end

    def missing_env_vars
      REQUIRED_ENV_VARS.select { |var| ENV[var].nil? }
    end
  end
end
