require "timed_cache"

class SpecialistSectorRegistry
  CACHE_LIFETIME_SECONDS = 300

  def initialize(index, clock = Time)
    @index = index
    @cache = TimedCache.new(CACHE_LIFETIME_SECONDS, clock) { fetch }
  end

  def [](slug)
    @cache.get[slug]
  end

private
  def fetch
    fields = %w{link title}
    Hash[@index.documents_by_format("specialist_sector", fields: fields).map { |document|
      # Specialist sector documents don't come from whitehall and so they don't
      # have a slug in search.  Panopticon constructs the link field from the
      # slug (held in panopticon) by adding a '/' prefix, so rather than do the
      # work now to add a slug and reindex the sectors, we construct a slug
      # field for the cached sector results in SpecialistSectorRegistry by
      # removing this '/'.
      #
      # This can be removed if the slug is ever actually added to
      # specialist_sector documents.
      fields = document.to_hash
      slug = fields["link"][1..-1]
      fields["slug"] = slug
      [slug, fields]
    }]
  end
end
