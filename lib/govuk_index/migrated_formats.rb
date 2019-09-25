module GovukIndex
  module MigratedFormats
    extend self

    def non_indexable?(format, path, app)
      non_indexable_formats[format] &&
        (non_indexable_formats[format] == :all || non_indexable_formats[format].include?(path) ||
          published_by_non_indexable_app?(format, app)) || non_indexable_path.include?(path)
    end

    def non_indexable_formats
      @non_indexable_formats ||= convert_to_allowed_hash(data_file["non_indexable"])
    end

    def non_indexable_path
      @non_indexable_path ||= data_file["non_indexable_path"]
    end

    def indexable?(format, path, app)
      indexable_formats[format] && (indexable_formats[format] == :all ||
        indexable_formats[format].include?(path) || published_by_indexable_app?(format, app))
    end

    def indexable_formats
      @indexable_formats ||= convert_to_allowed_hash(data_file["migrated"] + data_file["indexable"])
    end

    def migrated_formats
      @migrated_formats ||= convert_to_allowed_hash(data_file["migrated"])
    end

  private

    def data_file
      @data_file ||= YAML.load_file(File.join(__dir__, "../../config/govuk_index/migrated_formats.yaml"))
    end

    def convert_to_allowed_hash(formats)
      formats.inject({}) do |hash, format|
        if format.is_a?(Hash)
          hash.merge(format)
        else
          hash[format] = :all
          hash
        end
      end
    end

    def published_by_indexable_app?(format, app)
      return false unless indexable_formats[format].is_a?(Hash)

      indexable_formats[format]["publishing_app"] == app
    end

    def published_by_non_indexable_app?(format, app)
      return false unless non_indexable_formats[format].is_a?(Hash)

      non_indexable_formats[format]["publishing_app"] == app
    end
  end
end
