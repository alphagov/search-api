require_relative "env"
require 'active_support/core_ext/hash/keys'
require_relative 'exception_mailer'

def config_for(kind)
  YAML.load_file(File.expand_path("../#{kind}.yml", __FILE__))
end

def backend_config
  # Note that we're not recursively symbolising keys, because the config for
  # each backend is currently flat. We may need to revisit this.
  config_for(:backends)[ENV["RACK_ENV"]].symbolize_keys
end

set :router, config_for(:router)

set :backends, backend_config
set :elasticsearch_schema, config_for("elasticsearch_schema")

set :slimmer_headers, config_for(:slimmer_headers)

panopticon_api_credentials = config_for(:panopticon_api_credentials)[ENV["RACK_ENV"]]
panopticon_api_credentials.symbolize_keys!
panopticon_api_credentials.values.each(&:symbolize_keys!)
set :panopticon_api_credentials, panopticon_api_credentials

set :slimmer_asset_host, ENV["SLIMMER_ASSET_HOST"]
set :top_results, 4
set :max_more_results, 46
set :max_recommended_results, 2

set :recommended_format, "recommended-link"

set :boost_csv, "data/boosted_links.csv"

set :format_order, ['transaction', 'answer', 'programme', 'guide']

set :format_name_alternatives, {
  "programme" => "Benefits & credits",
  "transaction" => "Services",
  "local_transaction" => "Services",
  "place" => "Services",
  "answer" => "Quick answers",
  "specialist_guidance" => "Specialist guidance"
}

configure :development do
  set :protection, false
  use Slimmer::App, prefix: settings.router[:path_prefix], asset_host: settings.slimmer_asset_host
end

configure :production do
  if File.exist?("aws_secrets.yml")
    disable :show_exceptions
    use ExceptionMailer, YAML.load_file("aws_secrets.yml"),
        to: ['govuk-exceptions@digital.cabinet-office.gov.uk', 'govuk@gofreerange.com'],
        from: '"Winston Smith-Churchill" <winston@alphagov.co.uk>'
  end
  use Slimmer::App, prefix: settings.router[:path_prefix], asset_host: settings.slimmer_asset_host, cache_templates: true
end

configure :test do
  use Slimmer::App, prefix: settings.router[:path_prefix], asset_host: settings.slimmer_asset_host
end
