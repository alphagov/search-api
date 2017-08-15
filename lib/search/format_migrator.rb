module Search
  class FormatMigrator
    def self.migrated_formats
      @migrated_formats ||= YAML.load_file(File.join(__dir__, '../../config/migrated_formats.yaml'))['formats']
    end

    def initialize(base)
      @base = base
    end

    def call
      {
        indices: {
          indices: SearchConfig.instance.elasticsearch['content_index_names'],
          filter: excluding_formats,
          no_match_filter: only_formats
        }
      }
    end

    def migrated_formats
      self.class.migrated_formats
    end

  private

    def excluding_formats
      options = {}
      options[:should] = [@base] if @base
      options[:must_not] = { terms: { format: migrated_formats } } if migrated_formats.any?
      options.any? ? { bool: options } : {}
    end

    def only_formats
      return 'none' if migrated_formats.empty?
      options = {}
      options[:should] = [@base] if @base
      options[:must] = { terms: { format: migrated_formats } }
      { bool: options }
    end
  end
end
