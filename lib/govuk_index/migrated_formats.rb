module GovukIndex
  module MigratedFormats
    extend self

    def non_indexable?(format, path)
      non_indexable_path.include?(path) || non_indexable_formats[format] &&
        (non_indexable_formats[format] == :all || non_indexable_formats[format].include?(path))
    end

    def non_indexable_formats
      @non_indexable_formats ||= convert_to_allowed_hash(data_file["non_indexable"])
    end

    def non_indexable_path
      @non_indexable_path ||= data_file["non_indexable_path"]
    end

    def indexable?(format, path)
      allowed_formats[format] && (allowed_formats[format] == :all || allowed_formats[format].include?(path))
    end

    def allowed_formats
      @allowed_formats ||= convert_to_allowed_hash(data_file["allowed_formats"])
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
  end
end
