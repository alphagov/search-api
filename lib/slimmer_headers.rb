require "slimmer/headers"

class SlimmerHeaders
  include Slimmer::Headers
  attr_reader :headers

  def self.headers(hash)
    new.tap { |a| a.set_slimmer_headers(hash) }.headers
  end

  def initialize
    @headers = {}
  end
end
