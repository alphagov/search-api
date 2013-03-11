require "time"
require "securerandom"
require "rest-client"
require "cgi"
require "elasticsearch/index"

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
    def initialize(base_uri, name, index_settings, mappings)
      @base_uri = base_uri
      @client = Client.new(base_uri)
      @name = name
      @index_settings = index_settings
      @mappings = mappings
    end

    def create_index
      index_name = generate_name
      index_payload = @index_settings.merge("mappings" => @mappings)
      @client.put(
        "#{CGI.escape(index_name)}/",
        MultiJson.encode(index_payload),
        content_type: :json
      )

      Index.new(@base_uri, index_name, @mappings)
    end

    def switch_to(index)
      # Bail if there is an existing index with this name.
      # elasticsearch won't allow us to add an alias with the same name as an
      # existing index. If such an index exists, it hasn't yet been migrated to
      # the new alias-y way of doing things.
      #
      # TODO: add a way to migrate to the new alias-y way of doing things
      indices = MultiJson.decode(@client.get("_aliases"))
      if indices.include? @name
        raise RuntimeError, "There is an index called #{@name}"
      end

      # Response of the form:
      #   { "index_name" => { "aliases" => { "a1" => {}, "a2" => {} } }
      aliased_indices = indices.select { |name, details|
        details["aliases"].include? @name
      }

      # For any existing indices with this alias, remove the alias
      # We would normally expect 0 or 1 such index, but several is valid too
      actions = aliased_indices.keys.map { |index_name|
        { "remove" => { "index" => index_name, "alias" => @name } }
      }

      actions << { "add" => { "index" => index.index_name, "alias" => @name } }

      payload = { "actions" => actions }

      @client.post(
        "/_aliases",
        MultiJson.encode(payload),
        content_type: :json
      )
    end

    def current
      Index.new(@base_uri, @name, @mappings)
    end

    def index_names
      alias_map.keys
    end

    def clean
      alias_map.each do |name, details|
        delete(name) if details["aliases"].empty?
      end
    end

  private
    def generate_name
      # elasticsearch requires that all index names be lower case
      # (Thankfully, lower case ISO8601 timestamps are still valid)
      "#{@name}-#{Time.now.utc.iso8601}-#{SecureRandom.uuid}".downcase
    end

    def alias_map
      # Return a map of all aliases in this group, of the form:
      # { concrete_name => { "aliases" => { alias_name => {}, ... } }, ... }
      indices = MultiJson.decode(@client.get("_aliases"))
      indices.select { |name| name_pattern.match name }
    end

    def name_pattern
      %r{
        \A
        #{Regexp.escape(@name)}
        -
        \d{4}-\d{2}-\d{2}  # Date
        t
        \d{2}:\d{2}:\d{2}  # Time
        z
        -
        \h{8}-\h{4}-\h{4}-\h{4}-\h{12}  # UUID
        \Z
      }x
    end

    def delete(index_name)
      @client.delete CGI.escape(index_name)
    end
  end
end
