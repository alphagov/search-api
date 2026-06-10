class SearchConfig
  class << self
    attr_writer :instance

    %w[
      metasearch_index_name
      popularity_rank_offset
      auxiliary_index_names
      govuk_index_name
      page_traffic_index_name
    ].each do |config_method|
      define_method config_method do
        elasticsearch.fetch(config_method)
      end
    end

    def instance(cluster)
      Cache.get("#{Cache::CLUSTER}#{cluster.key}") do
        new(cluster)
      end
    end

    def default_instance
      # 'instance' doesn't have default parameters so that you have to
      # explicitly think about and opt into the default.
      instance(Clusters.default_cluster)
    end

    def search_servers
      Cache.get(Cache::SEARCH_SERVERS) do
        Clusters.active.map { |cluster| SearchConfig.instance(cluster).search_server }
      end
    end

    def all_index_names
      auxiliary_index_names + [govuk_index_name]
    end

    def run_search(raw_parameters)
      search_params = parse_parameters(raw_parameters)

      search_params.search_config.run_search_with_params(search_params)
    end

    def generate_query(raw_parameters)
      search_params = parse_parameters(raw_parameters)

      search_params.search_config.generate_query_for_params(search_params)
    end

    def parse_parameters(raw_parameters)
      parser = SearchParameterParser.new(raw_parameters, combined_index_schema)
      parser.validate!
      Search::QueryParameters.new(parser.parsed_params)
    end

    def elasticsearch
      Cache.get(Cache::SEARCH_CONFIG) do
        ElasticsearchConfig.new.config
      end
    end

  private

    def combined_index_schema
      # schema_config here corresponds to the default cluster, which is
      # fine because the 'elasticsearch_types' field (which the combined
      # index schema uses) is unaffected by the 'elasticsearch_settings'
      # field (which is what can be overridden per-cluster).
      Cache.get(Cache::COMBINED_INDEX_SCHEMA) do
        CombinedIndexSchema.new(
          [govuk_index_name],
          default_instance.schema_config,
        )
      end
    end
  end

  def initialize(cluster)
    @cluster = cluster
  end

  def search_server
    @search_server ||= SearchIndices::SearchServer.new(
      cluster.uri,
      schema_config,
      SearchConfig.auxiliary_index_names,
      SearchConfig.govuk_index_name,
      self,
    )
  end

  def schema_config
    @schema_config ||= SchemaConfig.new(
      ElasticsearchConfig.new.config_path,
      schema_config_file: cluster.schema_config_file,
    )
  end

  def run_search_with_params(search_params)
    searcher.run(search_params)
  end

  def generate_query_for_params(search_params)
    searcher.query(search_params)
  end

  def metasearch_index
    @metasearch_index ||= search_server.index(SearchConfig.metasearch_index_name)
  end

  def content_index
    @content_index ||= search_server.index(SearchConfig.govuk_index_name)
  end

  def base_uri
    cluster.uri
  end

  def get_index_for_alias(alias_name)
    client.indices.get_alias(index: alias_name).keys.first
  end

  def rank_eval(requests:, metric:, indices: "*")
    client.rank_eval(
      index: indices,
      body: { requests:, metric: },
    )
  end

private

  attr_accessor :cluster

  def searcher
    @searcher ||= Search::Query.new(
      content_index:,
      registries:,
      metasearch_index:,
    )
  end

  def registries
    @registries ||= Search::Registries.new(
      search_server,
      self,
    )
  end

  def client
    @client ||= Services.elasticsearch(hosts: base_uri)
  end
end
