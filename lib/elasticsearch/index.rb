module Elasticsearch
  class Index
    def initialize(base_uri, name, field_names)
      @index_uri = base_uri + "#{CGI.escape(name)}/"
      @name = name
      @field_names = field_names
    end
  end
end
