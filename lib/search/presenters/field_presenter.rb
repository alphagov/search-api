module Search
  class FieldPresenter
    attr_reader :registries

    def initialize(registries)
      @registries = registries
    end

    # Expand a field given a slug, if the field should be expanded.
    def expand(field, slug)
      if should_expand(field)
        value_by_slug(field, slug)
      else
        slug
      end
    end

  private

    # Return true if the field should be expanded (ie, there is a registry for
    # it).
    def should_expand(field)
      !!registries[field.to_sym]
    end

    # Return an expanded value for a field given a slug.  Always returns a hash
    # with at least the key "slug".
    def value_by_slug(field, slug)
      registry = registries[field.to_sym]
      if registry
        value = registry[slug]
        if value
          return value.merge("slug" => slug)
        end
      end
      { "slug" => slug }
    end
  end
end
