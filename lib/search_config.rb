class SearchConfig
  %w[
    registry_index
    metasearch_index_name
    popularity_rank_offset
    auxiliary_index_names
    content_index_names
    spelling_index_names
    base_uri
    govuk_index_name
  ].each do |config_method|
    define_method config_method do
      elasticsearch.fetch(config_method)
    end
  end

  class << self
    attr_writer :instance

    def instance
      @instance ||= new
    end
  end

  def search_server
    @server ||= SearchIndices::SearchServer.new(
      elasticsearch["base_uri"],
      schema_config,
      index_names,
      govuk_index_name,
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

  def run_search(raw_parameters)
    parser = SearchParameterParser.new(raw_parameters, combined_index_schema)
    parser.validate!

    search_params = Search::QueryParameters.new(parser.parsed_params)

    searcher.run(search_params)
  end

  def metasearch_index
    search_server.index(metasearch_index_name)
  end

  def spelling_index
    search_server.index_for_search(spelling_index_names)
  end

  def content_index
    search_server.index_for_search(content_index_names + [govuk_index_name])
  end

private

  def searcher
    @searcher ||= begin
      registries = Search::Registries.new(
        search_server,
        self
      )

      Search::Query.new(
        content_index: content_index,
        registries: registries,
        metasearch_index: metasearch_index,
        spelling_index: spelling_index
      )
    end
  end

  def combined_index_schema
    @combined_index_schema ||= CombinedIndexSchema.new(
      content_index_names,
      schema_config
    )
  end

  def config_path
    File.expand_path("../config/schema", File.dirname(__FILE__))
  end

  def config_path_for(kind)
    File.expand_path("../#{kind}.yml", File.dirname(__FILE__))
  end

  def config_for(kind)
    YAML.load(ERB.new(File.read(config_path_for(kind))).result)
  end
end
