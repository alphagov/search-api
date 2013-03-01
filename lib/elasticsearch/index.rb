module Elasticsearch
  class Index
    attr_reader :name, :field_names

    def initialize(base_uri, name, field_names)
      @index_uri = base_uri + "#{CGI.escape(name)}/"
      @name = name
      @field_names = field_names
    end
  end
end
