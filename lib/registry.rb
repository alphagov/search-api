require "timed_cache"

module Registry
  class BaseRegistry
    CACHE_LIFETIME = 300 # 5 minutes

    def initialize(index, field_definitions, format, fields = %w{slug link title}, clock = Time)
      @cache = TimedCache.new(self.class::CACHE_LIFETIME, clock) { fetch }

      @field_definitions = fields.reduce({}) { |result, field|
        result[field] = field_definitions[field]
        result
      }

      @format = format
      @index = index
    end

    def all
      @cache.get
    end

    def [](slug)
      all.find { |o| o.slug == slug }
    end

  private
    def fetch
      find_documents_by_format.to_a
    end

    def find_documents_by_format
      @index.documents_by_format(@format, @field_definitions)
    end
  end

  class DocumentCollection < BaseRegistry
    def initialize(index, field_definitions)
      super(index, field_definitions, "document_collection")
    end
  end

  class DocumentSeries < BaseRegistry
    def initialize(index, field_definitions)
      super(index, field_definitions, "document_series")
    end
  end

  class Organisation < BaseRegistry
    def self.load_ministerial_departments
      file_path = File.join(File.dirname(__FILE__), "..", "config", "ministerial_departments.txt")
      File.readlines(file_path).map(&:chomp).reject(&:empty?).map do |slug|
        "/government/organisations/#{slug}"
      end
    end

    MINISTERIAL_DEPARTMENT_LINKS = load_ministerial_departments
    MINISTERIAL_DEPARTMENT_TYPE = "Ministerial department"

    def initialize(index, field_definitions)
      super(index, field_definitions, "organisation", %w{slug link title acronym organisation_type organisation_state})
    end

  private
    def fetch
      find_documents_by_format.map { |o| fill_organisation_type(o) }
    end

    def fill_organisation_type(organisation)
      # If the organisation type isn't indexed, populate it if we know the
      # organisation is a ministerial department.
      if organisation.has_field?(:organisation_type) && organisation.organisation_type.nil?
        if MINISTERIAL_DEPARTMENT_LINKS.include?(organisation.link)
          organisation.organisation_type = MINISTERIAL_DEPARTMENT_TYPE
        end
      end

      organisation
    end
  end

  class SpecialistSector < BaseRegistry
    def initialize(index, field_definitions)
      super(index, field_definitions, "specialist_sector")
    end
  end

  class Topic < BaseRegistry
    def initialize(index, field_definitions)
      super(index, field_definitions, "topic")
    end
  end

  class WorldLocation < BaseRegistry
    def initialize(index, field_definitions)
      super(index, field_definitions, "world_location")
    end
  end

  class Person < BaseRegistry
    def initialize(index, field_definitions)
      super(index, field_definitions, "person")
    end
  end
end
