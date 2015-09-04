module ElasticsearchIntegrationHelpers
  AUXILIARY_INDEX_NAMES = ["page-traffic_test", "metasearch_test"]
  INDEX_NAMES = ["mainstream_test", "government_test"]
  DEFAULT_INDEX_NAME = INDEX_NAMES.first

  def check_index_name!(index_name)
    unless /^[a-z_-]+(_|-)test($|-)/.match(index_name)
      raise "#{index_name} is not a valid test index name"
    end
  end

  def stub_elasticsearch_settings
    (INDEX_NAMES + AUXILIARY_INDEX_NAMES).each do |n|
      check_index_name!(n)
    end

    app.settings.search_config.stubs(:elasticsearch).returns({
      "base_uri" => "http://localhost:9200",
      "content_index_names" => INDEX_NAMES,
      "auxiliary_index_names" => AUXILIARY_INDEX_NAMES,
      "metasearch_index_name" => "metasearch_test",
      "registry_index" => "government_test",
      "spelling_index_names" => INDEX_NAMES,
      "popularity_rank_offset" => 10,
    })
    app.settings.stubs(:default_index_name).returns(DEFAULT_INDEX_NAME)
    app.settings.stubs(:enable_queue).returns(false)
  end

  def search_config
    app.settings.search_config
  end

  def search_server
    search_config.search_server
  end

  def create_test_index(group_name = DEFAULT_INDEX_NAME)
    index_group = search_server.index_group(group_name)
    index = index_group.create_index
    index_group.switch_to(index)
  end

  def create_test_indexes
    (AUXILIARY_INDEX_NAMES + INDEX_NAMES).each do |index|
      create_test_index(index)
    end
  end

  def clean_test_indexes
    (AUXILIARY_INDEX_NAMES + INDEX_NAMES).each do |index|
      clean_index_group(index)
    end
  end

  def insert_stub_popularity_data(path)
    document_atts = {
      "path_components" => path,
      "rank_14" => 10,
    }

    RestClient.post "http://localhost:9200/page-traffic_test/page-traffic/#{CGI.escape(path)}", document_atts.to_json
    RestClient.post "http://localhost:9200/page-traffic_test/_refresh", nil
  end

  def try_remove_test_index(index_name = DEFAULT_INDEX_NAME)
    check_index_name!(index_name)
    RestClient.delete "http://localhost:9200/#{CGI.escape(index_name)}"
  rescue RestClient::ResourceNotFound
    # Index doesn't exist: that's fine
  end

  def clean_index_group(group_name = DEFAULT_INDEX_NAME)
    check_index_name!(group_name)
    index_group = search_server.index_group(group_name)
    # Delete any indices left over from switching
    index_group.clean
    # Clean up the test index too, to avoid the possibility of inter-dependent
    # tests. It also keeps the index view cleaner.
    if index_group.current.exists?
      index_group.send(:delete, index_group.current.real_name)
    end
  end

  def stub_index
    return @s if @s
    @s = stub("stub index")
    Rummager.any_instance.stubs(:current_index).returns(@s)
    Rummager.any_instance.stubs(:unified_index).returns(@s)
    @s
  end
end
