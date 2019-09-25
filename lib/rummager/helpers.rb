module Helpers
  include Rack::Utils
  alias_method :h, :escape_html

  def pluralize(singular, plural)
    @results.count == 1 ? singular : plural
  end

  def simple_json_result(is_ok)
    if is_ok
      json_result 200, "OK"
    else
      json_result 500, "error"
    end
  end

  def json_result(status_code, message)
    content_type :json
    status status_code
    { "result" => message }.to_json
  end

  # Parse a query string, returning a hash of arrays.
  #
  # Handles parameters named either simply with their name, or with their
  # name followed by a pair of square brackets (ie, "name[]").
  #
  # We do our own parameter parsing for the search endpoint because we don't
  # want to force callers to use the Ruby/PHP convention of adding a [] to the
  # end of a parameter name if the parameter has multiple values (but we also
  # have to support being called from Ruby tools which insist on doing this).
  def parse_query_string(query_string)
    CGI::parse(query_string).reduce({}) { |params, (name, values)|
      params.merge(name.sub(/\[\]\Z/, "") => values) { |_, old, new|
        old.concat(new)
      }
    }
  end
end

class HelperAccessor
  include Helpers
end
