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
    params = KeySpaceConstrainedParams.new

    (query_string || '').split(/[&;] */n).each do |p|
      name, value = p.split('=', 2).map { |s| unescape(s) }

      # Ignore parameters with missing names or values
      next if name.nil?

      name.gsub!(/\[\]\Z/, "")
      params[name] ||= []
      params[name] << value unless value.nil?
    end

    return params.to_params_hash
  end
end

class HelperAccessor
  include Helpers
end
