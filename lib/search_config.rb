require "yaml"
require "elasticsearch/search_server"
require "schema_config"
require "plek"

class SearchConfig
  def search_server
    @server ||= Elasticsearch::SearchServer.new(
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

  def content_index_names
    elasticsearch["content_index_names"] || []
  end

  def auxiliary_index_names
    elasticsearch["auxiliary_index_names"] || []
  end

  def elasticsearch
    @elasticsearch ||= config_for("elasticsearch")
  end

  def document_series_registry_index
    elasticsearch["document_series_registry_index"]
  end

  def document_collection_registry_index
    elasticsearch["document_collection_registry_index"]
  end

  def organisation_registry_index
    elasticsearch["organisation_registry_index"]
  end

  def topic_registry_index
    elasticsearch["topic_registry_index"]
  end

  def world_location_registry_index
    elasticsearch["world_location_registry_index"]
  end

  def govuk_index_names
    elasticsearch["govuk_index_names"]
  end

  def metasearch_index_name
    elasticsearch["metasearch_index_name"]
  end

private
  def config_path
    File.expand_path("../config/schema", File.dirname(__FILE__))
  end

  def in_development_environment?
    %w{development test}.include?(ENV['RACK_ENV'])
  end

  def config_for(kind)
    YAML.load_file(File.expand_path("../#{kind}.yml", File.dirname(__FILE__)))
  end
end
