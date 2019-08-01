require 'googleauth'

module Analytics
  class GoogleAnalyticsExportCredentials
    def self.authorization(scopes)
      ENV['GOOGLE_ACCOUNT_TYPE'] = "service_account"
      raise ArgumentError, "Must define GOOGLE_PRIVATE_KEY and GOOGLE_CLIENT_EMAIL in order to authenticate." unless all_configuration_in_env?

      Google::Auth.get_application_default(scopes)
    end

    def self.all_configuration_in_env?
      %w(GOOGLE_PRIVATE_KEY GOOGLE_CLIENT_EMAIL).all? { |env_var| ENV[env_var].present? }
    end
    private_class_method :all_configuration_in_env?
  end
end
