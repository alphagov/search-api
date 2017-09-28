class IndexHelpers
  def self.setup_test_indexes
    puts 'Setting up test indexes...'

    clean_all
    create_all

    puts 'Done.'
  end

  def self.all_index_names
    config = SearchConfig.instance
    config.content_index_names + config.auxiliary_index_names + [config.govuk_index_name]
  end

  def self.clean_all
    all_index_names.each do |index_name|
      clean_index_group(index_name)
    end
  end

  def self.clean_index_group(index_name)
    raise "Attempting to clean non-test index: #{index_name}" unless index_name =~ /test/

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
    all_index_names.each do |index|
      create_test_index(index)
    end
  end

  def self.create_test_index(group_name = DEFAULT_INDEX_NAME)
    search_server = SearchConfig.instance.search_server
    index_group = search_server.index_group(group_name)
    index = index_group.create_index
    index_group.switch_to(index)
  end
end
