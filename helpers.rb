# encoding: utf-8
module Helpers
  include Rack::Utils
  alias_method :h, :escape_html

  def pluralize(singular, plural)
    @results.count == 1 ? singular : plural
  end

  def simple_json_result(ok)
    if ok
      json_result 200, "OK"
    else
      json_result 500, "error"
    end
  end

  def json_result(status_code, message)
    content_type :json
    status status_code
    MultiJson.encode("result" => message)
  end
end

class HelperAccessor
  include Helpers
end
