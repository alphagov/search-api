helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def capped_search_set_size
    [@results.count, (settings.top_results + settings.max_more_results)].min
  end

  def top_results
    results = non_recommended_results[0..(settings.top_results-1)]
    results.empty? ? nil : results
  end

  def more_results
    non_recommended_results[settings.top_results..(settings.top_results + settings.max_more_results-1)]
  end

  def recommended_results
    @results.select { |r| r.format == settings.recommended_format }
  end

  def non_recommended_results
    @results.select { |r| r.format != settings.recommended_format }
  end

  def pluralize(singular, plural)
    @results.count == 1 ? singular : plural
  end

  def include(name)
    begin
      File.open("views/_#{name}.html").read
    rescue Errno::ENOENT
    end
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
