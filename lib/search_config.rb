require "yaml"
require "elasticsearch/search_server"

class SearchConfig

  def search_server
    Elasticsearch::SearchServer.new(
      elasticsearch["base_uri"],
      elasticsearch_schema,
      index_names
    )
  end

  def index_names
    elasticsearch["index_names"]
  end

  def elasticsearch_schema
    @elasticsearch_schema ||= config_for("elasticsearch_schema")
  end

  def elasticsearch
    @elasticsearch ||= config_for("elasticsearch")
  end

  def document_series_registry_index
    elasticsearch["document_series_registry_index"]
  end

  def organisation_registry_index
    elasticsearch["organisation_registry_index"]
  end

  def topic_registry_index
    elasticsearch["topic_registry_index"]
  end

private
  def config_for(kind)
    YAML.load_file(File.expand_path("../#{kind}.yml", File.dirname(__FILE__)))
  end
end
