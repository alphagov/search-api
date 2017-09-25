class IndexHelpers
  AUXILIARY_INDEX_NAMES = ["page-traffic_test", "metasearch_test"].freeze
  INDEX_NAMES = %w(mainstream_test government_test).freeze
  GOVUK_INDEX_NAME = "govuk_test".freeze
  DEFAULT_INDEX_NAME = INDEX_NAMES.first
  ALL_TEST_INDEXES = ([GOVUK_INDEX_NAME] + AUXILIARY_INDEX_NAMES + INDEX_NAMES).freeze

  def self.setup_test_indexes
    puts 'Setting up test indexes...'

    stub_elasticsearch_settings
    clean_all
    create_all

    puts 'Done.'
  end

  def self.check_index_name!(index_name)
    unless /^[a-z_-]+(_|-)test($|-)/ =~ index_name
      raise "#{index_name} is not a valid test index name"
    end
  end

  def self.clean_all
    ALL_TEST_INDEXES.each do |index_name|
      clean_index_group(index_name)
    end
  end

  def self.clean_index_group(index_name)
    check_index_name!(index_name)

    search_server = SearchConfig.instance.search_server
    index_group = search_server.index_group(index_name)

    # Delete any indices left over
    index_group.clean

    # Clean up the test index too
    if index_group.current.exists?
      index_group.send(:delete, index_group.current.real_name)
    end
  end

  def self.create_all
    ALL_TEST_INDEXES.each do |index|
      create_test_index(index)
    end
  end

  def self.create_test_index(group_name = DEFAULT_INDEX_NAME)
    search_server = SearchConfig.instance.search_server
    index_group = search_server.index_group(group_name)
    index = index_group.create_index
    index_group.switch_to(index)
  end

  def self.stub_elasticsearch_settings(search_config = SearchConfig.instance)
    ALL_TEST_INDEXES.each do |index_name|
      check_index_name!(index_name)
    end

    search_config.stubs(:elasticsearch).returns({
      "base_uri" => ELASTICSEARCH_TESTING_HOST,
      "content_index_names" => INDEX_NAMES,
      "govuk_index_name" => GOVUK_INDEX_NAME,
      "auxiliary_index_names" => AUXILIARY_INDEX_NAMES,
      "metasearch_index_name" => "metasearch_test",
      "registry_index" => "government_test",
      "spelling_index_names" => INDEX_NAMES,
      "popularity_rank_offset" => 10,
    })
    Rummager.settings.stubs(:default_index_name).returns(DEFAULT_INDEX_NAME)
  end
end
