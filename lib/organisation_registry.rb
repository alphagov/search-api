require "timed_cache"

class OrganisationRegistry
  CACHE_LIFETIME = 12 * 3600  # 12 hours

  def self.load_ministerial_departments
    file_path = File.join(File.dirname(__FILE__), "..", "config", "ministerial_departments.txt")
    File.readlines(file_path).map(&:chomp).reject(&:empty?).map do |slug|
      "/government/organisations/#{slug}"
    end
  end

  MINISTERIAL_DEPARTMENT_LINKS = load_ministerial_departments

  MINISTERIAL_DEPARTMENT_TYPE = "Ministerial department"

  def initialize(index, clock = Time)
    @index = index
    @cache = TimedCache.new(CACHE_LIFETIME, clock) { fetch }
  end

  def all
    @cache.get
  end

  def [](slug)
    @cache.get.find { |o| o.slug == slug }
  end

private
  def fetch
    fields = %w{slug link title acronym organisation_type organisation_state}
    organisations = @index.documents_by_format("organisation", fields: fields)
    organisations.map do |o|
      fill_organisation_type(o)
    end
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
