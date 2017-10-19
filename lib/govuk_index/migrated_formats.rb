module GovukIndex
  module MigratedFormats
    extend self

    def indexable?(format)
      indexable_formats.include?(format)
    end

    def migrated_formats
      @migrated_formats ||= YAML.load_file(File.join(__dir__, '../../config/govuk_index/migrated_formats.yaml'))['migrated']
    end

    def indexable_formats
      @indexable_formats ||= YAML.load_file(File.join(__dir__, '../../config/govuk_index/migrated_formats.yaml')).values.flatten
    end
  end
end
