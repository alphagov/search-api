require "timed_cache"

class OrganisationRegistry
  CACHE_LIFETIME = 12 * 3600  # 12 hours

  def initialize(index, clock = Time)
    @index = index
    @cache = TimedCache.new(CACHE_LIFETIME, clock) { fetch }
  end

  def [](slug)
    @cache.get.find { |o| o.link == "/government/organisations/#{slug}" }
  end

private
  def fetch
    fields = %w{link title acronym}
    organisations = @index.documents_by_format("organisation", fields: fields)
    organisations.map { |o| fix_acronym(o) }
  end

  def fix_acronym(organisation)
    # If an organisation doesn't have an acronym specified, and if there is one
    # in the title, extract it.
    #
    # HACK: this is to get around the smushing together of title and acronym in
    # the current index. Once they are separate, this code can be removed.

    # e.g. "Ministry of Justice (MoJ)"

    if organisation.has_field?(:acronym) && organisation.acronym.nil?
      merged_pattern = %r{\A(?<title>.+) \((?<acronym>[^)]+)\)\Z}

      pattern_match = merged_pattern.match(organisation.title)
      if pattern_match
        organisation.title = pattern_match["title"]
        organisation.acronym = pattern_match["acronym"]
      end
    end
    organisation
  end
end
