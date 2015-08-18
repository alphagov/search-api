class HighlightedTitle
  attr_reader :raw_result

  def initialize(raw_result)
    @raw_result = raw_result
  end

  def text
    highlighted_title || original_title
  end

private

  def highlighted_title
    # `highlight` will be missing if none of the search terms match what's in
    # the title, eg. when displaying best bets.
    raw_result['highlight'] &&
      raw_result['highlight']['title'].to_a.first
  end

  def original_title
    Rack::Utils.escape_html(raw_result['fields']['title'])
  end
end
