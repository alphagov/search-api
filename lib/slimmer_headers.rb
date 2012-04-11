require "slimmer/headers"

# Lightweight container for Slimmer's header manipulation.
#
# Slimmer's Headers module is intended to be included into a class with a
# `headers` hash, such as a Rails controller. Because Sinatra sets headers with
# a method, rather than setting them in a hash, we need a container to store
# them until we're ready to use them.
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
