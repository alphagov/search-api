require "yaml"
require "search_server"
require "schema/schema_config"
require "plek"

class SearchConfig
  %w[
    registry_index
    metasearch_index_name
    popularity_rank_offset
    auxiliary_index_names
    content_index_names
    spelling_index_names
    repository_name
  ].each do |config_method|
    define_method config_method do
      elasticsearch.fetch(config_method)
    end
  end

  def search_server
    @server ||= SearchIndices::SearchServer.new(
      elasticsearch["base_uri"],
      schema_config,
      index_names,
      content_index_names,
      self,
    )
  end

  def schema_config
    @schema ||= SchemaConfig.new(config_path)
  end

  def index_names
    content_index_names + auxiliary_index_names
  end

  def elasticsearch
    @elasticsearch ||= config_for("elasticsearch")
  end


private

  def config_path
    File.expand_path("../config/schema", File.dirname(__FILE__))
  end

  def config_for(kind)
    YAML.load_file(File.expand_path("../#{kind}.yml", File.dirname(__FILE__)))
  end
end
