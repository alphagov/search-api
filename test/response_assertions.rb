require "htmlentities"

module ResponseAssertions
  def assert_response_text(needle)
    haystack = HTMLEntities.new.decode(last_response.body.gsub(/<[^>]+>/, " ").gsub(/\s+/, " "))
    message = "Expected to find #{needle.inspect} in\n#{haystack}"
    assert haystack.include?(needle), message
  end
end
