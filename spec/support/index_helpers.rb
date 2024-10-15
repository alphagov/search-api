class IndexHelpers
  def self.setup_test_indexes
    puts "Setting up test indexes on clusters #{Clusters.active.map(&:key).join(',')}..."
    start_time = Time.now

    create_all

    puts "Done in #{Time.now - start_time} seconds."
  end

  def self.all_index_names
    SearchConfig.content_index_names + SearchConfig.auxiliary_index_names + [SearchConfig.govuk_index_name]
  end

  def self.clean_all
    all_index_names.append(SearchConfig.specialist_finder_index_name).each do |index_name|
      clean_index_group(index_name)
    end
  end

  def self.clean_index_group(index_name)
    raise "Attempting to clean non-test index: #{index_name}" unless index_name =~ /test/

    Clusters.active.each do |cluster|
      search_server = SearchConfig.instance(cluster).search_server
      index_group = search_server.index_group(index_name)

      # Delete any indices left over
      index_group.clean

      # Clean up the test index too
      if index_group.current.exists?
        index_group.send(:delete, index_group.current.real_name)
      end
    end
  end

  def self.create_all
    all_index_names.append(SearchConfig.specialist_finder_index_name).each do |index|
      create_test_index(index)
    end
  end

  def self.create_test_index(group_name = DEFAULT_INDEX_NAME)
    Clusters.active.each do |cluster|
      index_group = SearchConfig.instance(cluster).search_server.index_group(group_name)
      index = index_group.create_index
      index_group.switch_to(index)
    end
  end
end
