class SearchConfig
  class << self
    attr_writer :instance

    %w[
      registry_index
      metasearch_index_name
      popularity_rank_offset
      auxiliary_index_names
      content_index_names
      spelling_index_names
      govuk_index_name
      page_traffic_index_name
    ].each do |config_method|
      define_method config_method do
        elasticsearch.fetch(config_method)
      end
    end

    def instance(cluster)
      @instance ||= {}
      @instance[cluster.key] ||= new(cluster)
    end

    def default_instance
      # 'instance' doesn't have default parameters so that you have to
      # explicitly think about and opt into the default.
      instance(Clusters.default_cluster)
    end

    def reset_instances
      # used in the tests because SearchConfig.instance is stateful
      @instance = {}
    end

    def search_servers
      @search_servers ||= begin
        Clusters.active.map { |cluster| SearchConfig.instance(cluster).search_server }
      end
    end

    def index_names
      content_index_names + auxiliary_index_names
    end

    def all_index_names
      # this is used to process data in the rake file when `all` is passed in as previous we skipped `govuk`
      # we can't update index_names at this stage as it is used in multiple spots including the index filtering
      content_index_names + auxiliary_index_names + [govuk_index_name]
    end

    def run_search(raw_parameters)
      parser = SearchParameterParser.new(raw_parameters, combined_index_schema)
      parser.validate!

      search_params = Search::QueryParameters.new(parser.parsed_params)

      instance(search_params.cluster).run_search_with_params(search_params)
    end

    def run_batch_search(searches)
      search_params = []
      searches.each do |search|
        parser = SearchParameterParser.new(search, combined_index_schema)
        parser.validate!

        search_params << Search::QueryParameters.new(parser.parsed_params)
      end

      instance(search_params.first.cluster).run_batch_search_with_params(search_params)
    end

    def elasticsearch
      @elasticsearch ||= es_config.config
    end

    def es_config
      @es_config ||= ElasticsearchConfig.new
    end

  private

    def combined_index_schema
      # schema_config here corresponds to the default cluster, which is
      # fine because the 'elasticsearch_types' field (which the combined
      # index schema uses) is unaffected by the 'elasticsearch_settings'
      # field (which is what can be overridden per-cluster).
      @combined_index_schema ||= CombinedIndexSchema.new(
        content_index_names + [govuk_index_name],
        default_instance.schema_config
      )
    end
  end

  def initialize(cluster)
    @cluster = cluster
  end

  def search_server
    @search_server ||= SearchIndices::SearchServer.new(
      cluster.uri,
      schema_config,
      SearchConfig.index_names,
      SearchConfig.govuk_index_name,
      SearchConfig.content_index_names,
      self,
    )
  end

  def schema_config
    @schema_config ||= SchemaConfig.new(
      SearchConfig.es_config.config_path,
      schema_config_file: cluster.schema_config_file,
    )
  end

  def run_search_with_params(search_params)
    searcher.run(search_params)
  end

  def run_batch_search_with_params(search_params)
    batch_searcher.run(search_params)
  end

  def metasearch_index
    @metasearch_index ||= search_server.index(SearchConfig.metasearch_index_name)
  end

  def spelling_index
    @spelling_index ||= search_server.index_for_search(SearchConfig.spelling_index_names)
  end

  def content_index
    @content_index ||= search_server.index_for_search(SearchConfig.content_index_names + [SearchConfig.govuk_index_name])
  end

  def old_content_index
    @old_content_index ||= search_server.index_for_search(SearchConfig.content_index_names)
  end

  def new_content_index
    @new_content_index ||= search_server.index_for_search([SearchConfig.govuk_index_name])
  end

private

  attr_accessor :cluster

  def searcher
    @searcher ||= Search::Query.new(
      content_index: content_index,
      registries: registries,
      metasearch_index: metasearch_index,
      spelling_index: spelling_index,
    )
  end

  def batch_searcher
    @batch_searcher ||= Search::BatchQuery.new(
      content_index: content_index,
      registries: registries,
      metasearch_index: metasearch_index,
      spelling_index: spelling_index,
    )
  end

  def registries
    @registries ||= Search::Registries.new(
      search_server,
      self,
    )
  end
end
