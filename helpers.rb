# encoding: utf-8
module Helpers
  include Rack::Utils
  alias_method :h, :escape_html

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
    MultiJson.encode("result" => result)
  end
end

class HelperAccessor
  include Helpers
end
