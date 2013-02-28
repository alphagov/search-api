require "time"
require "securerandom"
require "rest-client"
require "cgi"

module Elasticsearch

  # A group of related indexes.
  #
  # An index group, say "mainstream", consists of a number of indexes of the
  # form "mainstream-<timestamp>-<uuid>". For example:
  #
  #   mainstream-2013-02-28t15:51:12z-50e3251b-869b-4894-b83c-de4675cefff6
  #
  # One of these indexes is aliased to the group name itself.
  class IndexGroup
    def initialize(search_server, name, index_settings, mappings)
      @search_server = search_server
      @name = name
      @index_settings = index_settings
      @mappings = mappings
    end

    def create_index
      index_name = generate_name
      index_payload = @index_settings.merge("mappings" => @mappings)
      index_url = (@search_server.base_url + "#{CGI.escape(index_name)}/").to_s
      RestClient.put(index_url, MultiJson.encode(index_payload), content_type: :json)

      # Return new Index object
      return true
    end

  private
    def generate_name
      # elasticsearch requires that all index names be lower case
      # (Thankfully, lower case ISO8601 timestamps are still valid)
      "#{@name}-#{Time.now.utc.iso8601}-#{SecureRandom.uuid}".downcase
    end
  end
end
