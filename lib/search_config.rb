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

    def instance
      @instance ||= new
    end

    def search_servers
      @search_servers ||= begin
        Clusters.active.map { |cluster| instance.search_server(cluster: cluster) }
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

      instance.run_search_with_params(search_params)
    end

    def run_batch_search(searches)
      search_params = []
      searches.each do |search|
        parser = SearchParameterParser.new(search, combined_index_schema)
        parser.validate!

        search_params << Search::QueryParameters.new(parser.parsed_params)
      end

      instance.run_batch_search_with_params(search_params)
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
        instance.schema_config
      )
    end
  end

  def search_server(cluster: Clusters.default_cluster)
    meta_assign(__method__, cluster) do
      SearchIndices::SearchServer.new(
        cluster.uri,
        schema_config(cluster: cluster),
        SearchConfig.index_names,
        SearchConfig.govuk_index_name,
        SearchConfig.content_index_names,
        self,
      )
    end
  end

  def schema_config(cluster: Clusters.default_cluster)
    meta_assign(__method__, cluster) do
      SchemaConfig.new(
        SearchConfig.es_config.config_path,
        schema_config_file: cluster.schema_config_file,
      )
    end
  end

  def run_search_with_params(search_params)
    searcher(cluster: search_params.cluster).run(search_params)
  end

  def run_batch_search_with_params(search_params)
    batch_searcher(cluster: search_params.first.cluster).run(search_params)
  end

  def metasearch_index(cluster: Clusters.default_cluster)
    meta_assign(__method__, cluster) do
      search_server(cluster: cluster).index(SearchConfig.metasearch_index_name)
    end
  end

  def spelling_index(cluster: Clusters.default_cluster)
    meta_assign(__method__, cluster) do
      search_server(cluster: cluster).index_for_search(SearchConfig.spelling_index_names)
    end
  end

  def content_index(cluster: Clusters.default_cluster)
    meta_assign(__method__, cluster) do
      search_server(cluster: cluster).index_for_search(SearchConfig.content_index_names + [SearchConfig.govuk_index_name])
    end
  end

  def old_content_index(cluster: Clusters.default_cluster)
    meta_assign(__method__, cluster) do
      search_server(cluster: cluster).index_for_search(SearchConfig.content_index_names)
    end
  end

  def new_content_index(cluster: Clusters.default_cluster)
    meta_assign(__method__, cluster) do
      search_server(cluster: cluster).index_for_search([SearchConfig.govuk_index_name])
    end
  end

private

  def searcher(cluster: Clusters.default_cluster)
    meta_assign(__method__, cluster) do
      Search::Query.new(
        content_index: content_index(cluster: cluster),
        registries: registries(cluster: cluster),
        metasearch_index: metasearch_index(cluster: cluster),
        spelling_index: spelling_index(cluster: cluster),
      )
    end
  end

  def batch_searcher(cluster: Clusters.default_cluster)
    meta_assign(__method__, cluster) do
      Search::BatchQuery.new(
        content_index: content_index(cluster: cluster),
        registries: registries(cluster: cluster),
        metasearch_index: metasearch_index(cluster: cluster),
        spelling_index: spelling_index(cluster: cluster),
      )
    end
  end

  def registries(cluster: Clusters.default_cluster)
    meta_assign(__method__, cluster) do
      @registries ||= Search::Registries.new(
        search_server(cluster: cluster),
        self
      )
    end
  end

  def meta_assign(method, cluster, &block)
    Clusters.validate_cluster_key!(cluster.key)

    # Lets us cache instance variables on a per-cluster basis.
    @cached_methods ||= {}
    @cached_methods["#{method}_for_cluster_#{cluster.key}"] ||= block.call
  end
end
