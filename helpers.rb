# encoding: utf-8
require "config"
require "solr_wrapper"

module Helpers
  HIGHLIGHT_START = SolrWrapper::HIGHLIGHT_START
  HIGHLIGHT_END   = SolrWrapper::HIGHLIGHT_END

  include Rack::Utils
  alias_method :h, :escape_html

  def proposition
    settings.slimmer_headers[:proposition]
  end

  def capped_search_set_size
    total_count = @results.count
    total_count += @secondary_results.count if settings.feature_flags[:use_secondary_solr_index]
    [total_count, (settings.top_results + settings.max_more_results)].min
  end

  def base_url
    return "https://www.gov.uk" if ENV['FACTER_govuk_platform'] == 'production'
    "https://www.#{ENV['FACTER_govuk_platform']}.alphagov.co.uk"
  end

  def top_results
    results = non_recommended_results[0..(settings.top_results-1)]
    results.empty? ? nil : results
  end

  def more_results
    non_recommended_results[settings.top_results..(settings.top_results + settings.max_more_results-1)]
  end

  def recommended_results
    @results.select { |r| r.format == settings.recommended_format }[0, settings.max_recommended_results]
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

  def apply_highlight(s)
    s.strip!
    return "" if s.empty?

    # If the first character is punctuation, remove it.
    s = s.slice(1..-1) while s[0].match(/\A[[:punct:]]/)
    s.strip!

    # If the first two characters are a single letter and space,
    # remove it.
    if s.slice(0..1).match(/[[:alpha:]]\s/) and not %w(a A i I).include?(s[0])
      s = s.slice(2..-1)
      s.strip!
    end

    just_text = s.gsub(/#{HIGHLIGHT_START}|#{HIGHLIGHT_END}/, "")
    [just_text.match(/\A[[:upper:]]/) || just_text.match(/\A[[:punct:]]/) ? "" : "… ",
     s.gsub(HIGHLIGHT_START, %{<strong class="highlight">}).
     gsub(HIGHLIGHT_END, %{</strong>}),
     just_text.match(/[\.\?!]\z/) ? "" : " …"].join
  end

  def map_section_name(slug)
    map = {
      "life-in-the-uk" => "Life in the UK",
      "council-tax" => "Council Tax",
      "housing-benefits-grants-and-schemes" => "Housing benefits, grants and schemes",
      "work-related-benefits-and-schemes" => "Work-related benefits and schemes",
      "buying-selling-a-vehicle" => "Buying/selling a vehicle",
      "owning-a-car-motorbike" => "Owning a car/motorbike",
      "council-and-housing-association-homes" => "Council and housing association homes",
      "animals-food-and-plants" => "Animals, food and plants",
      "mot" => "MOT"
    }
    return map[slug] ? map[slug] : false
  end

  def humanize_section_name(slug)
    slug.gsub('-', ' ').capitalize
  end

  def formatted_section_name(slug)
    map_section_name(slug) ? map_section_name(slug) : humanize_section_name(slug)
  end

  def group_by_format(results)
    results.group_by(&:humanized_format).sort_by do |presentation_format_name, results|
      sort_order = ['Quick answers', 'Guides', 'Services', 'Benefits & credits']
      sort_order.find_index(presentation_format_name) || sort_order.size
    end
  end
end

class HelperAccessor
  include Helpers
end
