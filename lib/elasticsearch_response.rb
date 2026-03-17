# frozen_string_literal: true

class ElasticsearchResponse
  def initialize(response)
    @response = response
  end

  # Returns the total hits count as Integer. Compatible with Elasticsearch 6.x and 7.x.
  def total_hits
    total = @response.dig("hits", "total")
    total = total["value"] if total.is_a?(Hash)
    total || 0
  end
end
