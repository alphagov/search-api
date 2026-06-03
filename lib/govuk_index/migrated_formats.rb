module GovukIndex
  module MigratedFormats
    extend self

    def disallowed?(format, path)
      disallowed_paths.include?(path) || disallowed_formats[format] &&
        (disallowed_formats[format] == :all || disallowed_formats[format].include?(path))
    end

    def disallowed_formats
      @disallowed_formats ||= convert_to_allowed_hash(data_file["disallowed_formats"])
    end

    def disallowed_paths
      @disallowed_paths ||= data_file["disallowed_paths"]
    end

    def allowed?(format, path)
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
