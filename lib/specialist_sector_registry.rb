require "timed_cache"

class SpecialistSectorRegistry
  CACHE_LIFETIME_SECONDS = 1800

  def initialize(index, clock = Time)
    @index = index
    @cache = TimedCache.new(CACHE_LIFETIME_SECONDS, clock) { fetch }
  end

  def [](slug)
    @cache.get.find { |o| o.slug == slug }
  end

private
  def fetch
    fields = %w{slug link title}
    @index.documents_by_format("specialist_sector", fields: fields).to_a
  end
end
