require "bearer_token_model"

Warden::Strategies.add :gds_bearer_token, Warden::OAuth2::Strategies::Bearer

Warden::Manager.before_failure do |env, opts|
  # TODO explain why
  env["REQUEST_METHOD"] = "POST"
end

Warden::OAuth2.configure do |config|
  config.token_model = BearerTokenModel
end

use Warden::Manager do |config|
  config.default_strategies [:gds_bearer_token]
  config.failure_app = Rummager
  config.intercept_401 = false
 end
