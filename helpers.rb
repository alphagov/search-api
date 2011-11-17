helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def capped_search_set_size
    [@results.count, (settings.top_results + settings.max_more_results)].min
  end

  def top_results
    results = @results[0..(settings.top_results-1)]
    results.empty? ? nil : results
  end

  def more_results
    @results[settings.top_results..(settings.top_results + settings.max_more_results-1)]
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
