require "yaml"
require "elasticsearch/search_server"
require "schema_config"
require "entity_extractor_client"
require "connection_error_swallower"
require "plek"

class SearchConfig
  attr_accessor :enable_entity_extraction

  def initialize
    @enable_entity_extraction = nil
  end

  def search_server
    Elasticsearch::SearchServer.new(
      elasticsearch["base_uri"],
      elasticsearch_schema,
      index_names,
      content_index_names,
      self,
    )
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

  def elasticsearch_schema
    config_path = File.expand_path("../config/schema", File.dirname(__FILE__))
    @elasticsearch_schema ||= SchemaConfig.new(config_path).elasticsearch_schema
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

  def entity_extractor
    raise "Must set 'enable_entity_extraction' in initializer" if @enable_entity_extraction.nil?
    @entity_extractor ||= if @enable_entity_extraction
      if in_development_environment?
        error_swallowing_entity_extractor
      else
        standard_entity_extractor
      end
    else
      null_entity_extractor
    end
  end

private
  def standard_entity_extractor
    EntityExtractorClient.new(Plek.current.find('entity-extractor'))
  end

  def error_swallowing_entity_extractor
    ConnectionErrorSwallower.new(standard_entity_extractor)
  end

  def null_entity_extractor
    ->(_) { [] }
  end

  def in_development_environment?
    %w{development test}.include?(ENV['RACK_ENV'])
  end

  def config_for(kind)
    YAML.load_file(File.expand_path("../#{kind}.yml", File.dirname(__FILE__)))
  end
end
