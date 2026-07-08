# frozen_string_literal: true

class OpenSearchResponse
  def initialize(response)
    @response = response
  end

  # Returns the total hits count as Integer.
  def total_hits
    @response.dig("hits", "total", "value")
  end
end
