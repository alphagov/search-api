# encoding: utf-8
module Helpers
  include Rack::Utils
  alias_method :h, :escape_html

  def base_url
    return "https://www.gov.uk" if ENV['FACTER_govuk_platform'] == 'production'
    "https://www.#{ENV['FACTER_govuk_platform']}.alphagov.co.uk"
  end

  def pluralize(singular, plural)
    @results.count == 1 ? singular : plural
  end

  def simple_json_result(ok)
    content_type :json
    if ok
      result = "OK"
    else
      result = "error"
      status 500
    end
    JSON.dump("result" => result)
  end
end

class HelperAccessor
  include Helpers
end
