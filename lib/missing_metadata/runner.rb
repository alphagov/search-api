module MissingMetadata
  class Runner
    PAGE_SIZE = 200
    MAX_PAGES = 52

    def initialize(missing_field_name, search_config: SearchConfig.default_instance, logger: $stdout)
      @missing_field_name = missing_field_name
      @search_config = search_config
      publishing_api = Services.publishing_api
      @logger = logger
      @fetcher = MissingMetadata::Fetcher.new(publishing_api, logger)
    end

    def update
      records = retrieve_records_with_missing_value

      total = records.size

      records.each_with_index do |result, i|
        logger.puts "Updating #{i}/#{total}: #{result[:_id]}"

        begin
          @fetcher.add_metadata(result)
        rescue StandardError
          logger.puts "Skipped result #{result[:elasticsearch_type]}/#{result[:_id]}: #{$ERROR_INFO}"
        end
      end
    end

    def retrieve_records_with_missing_value
      results = []

      (0..Float::INFINITY).lazy.each do |page|
        logger.puts "Fetching page #{page + 1}"

        response = SearchConfig.run_search(
          "filter_#{@missing_field_name}" => %w[_MISSING],
          "count" => [PAGE_SIZE.to_s],
          "start" => [(page * PAGE_SIZE).to_s],
          "fields" => %w[content_id],
        )

        break if response[:results].empty?

        response[:results].each do |result|
          if result[:_id].start_with?("https://", "http://")
            logger.puts "Skipping #{result[:elasticsearch_type]}/#{result[:_id]}"
            next
          end

          results << result.symbolize_keys.slice(:_id, :index, :content_id)
        end
      end

      results
    end

  private

    attr_reader :search_config, :logger
  end
end
