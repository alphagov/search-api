require "time"

class OrganisationRegistry
  CACHE_LIFETIME = 12 * 3600

  def initialize(index, clock = DateTime)
    @index = index
    @clock = clock
    @cache_updated = nil
  end

  def [](slug)
    organisations.find { |o| o.link == "/government/organisations/#{slug}" }
  end

private
  def organisations
    if refresh_needed?
      @organisations = fetch
      @cache_updated = @clock.now
    end
    @organisations
  end

  def fetch
    fields = %w{link title}
    @index.documents_by_format("organisation", fields: fields).to_a
  end

  def refresh_needed?
    @organisations.nil? || @cache_updated.nil? || cache_age >= CACHE_LIFETIME
  end

  def cache_age
    @clock.now - @cache_updated
  end
end
