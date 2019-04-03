class VirtualFilterParser
  def initialize(filter_hashes, errors)
    @filter_hashes = filter_hashes
    @errors = errors
  end

  def parse
    # This (currently) only does one thing.
    # If there is a filter 'filter_research_and_statistics'
    # For the types 'upcoming_statistics, 'published_statistics' and 'research' it will amend the filter hashes
    # to contain the relevant filters
    # It will overwrite any existing conflicting filters

    research_and_statistics_type = nil
    filter_hashes.each do |filter|
      if filter['full_name'] == 'filter_research_and_statistics'
        research_and_statistics_type = filter
      end
    end

    if research_and_statistics_type
      filter_hashes.delete_if { |filter| filter['full_name'] == 'filter_research_and_statistics' }
      case research_and_statistics_type['values'].first
      when 'upcoming_statistics'
        filter_upcoming_statistics
      when 'published_statistics'
        filter_published_statistics
      when 'research'
        filter_research
      else
        errors << "Value provided for filter_research_and_statistics is not recognised
          (provided: #{research_and_statistics_type['values'].join(',')}, must be 'upcoming_statistics',
          'published_statistics' or 'research')"
      end
    end
    [filter_hashes, errors]
  end

  def self.virtual_filters
    %w[research_and_statistics].freeze
  end

private

  attr_reader :filter_hashes, :errors

  def filter_upcoming_statistics
    filter_hashes.delete_if do |filter|
      filter['full_name'] == 'filter_release_timestamp' ||
        filter['full_name'] == 'filter_format'
    end

    filter_hashes << {
        'full_name' => 'filter_release_timestamp',
        'operation' => 'filter',
        'multivalue_query' => nil,
        'name' => 'release_timestamp',
        'values' => ["from:#{Date.today.iso8601}"]
    }

    filter_hashes << {
        'full_name' => 'filter_format',
        'operation' => 'filter',
        'multivalue_query' => nil,
        'name' => 'format',
        'values' => %w(statistics_announcement)
    }
  end

  def filter_published_statistics
    filter_hashes.delete_if { |filter| filter['full_name'] == 'filter_content_store_document_type' }

    filter_hashes << {
        'full_name' => 'filter_content_store_document_type',
        'operation' => 'filter',
        'multivalue_query' => nil,
        'name' => 'content_store_document_type',
        'values' => %w(statistics national_statistics statistical_data_set official_statistics)
    }
  end

  def filter_research
    filter_hashes.delete_if { |filter| filter['full_name'] == 'filter_content_store_document_type' }

    filter_hashes << {
        'full_name' => 'filter_content_store_document_type',
        'operation' => 'filter',
        'multivalue_query' => nil,
        'name' => 'content_store_document_type',
        'values' => %w(dfid_research_output independent_report research)
    }
  end
end
