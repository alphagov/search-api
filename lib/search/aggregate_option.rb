module Search
  # An option in a list of aggregates
  # Knows how to compare itself to other options, for sorting.
  class AggregateOption
    attr_reader :value, :count, :applied

    include Comparable

    def initialize(value, count, applied, orderings)
      @value = value
      @count = count
      @applied = applied
      @orderings = orderings
    end

    def as_hash
      {
        value: @value,
        documents: @count,
      }
    end

    def <=>(other)
      @orderings.each do |ordering, dir|
        cmp = cmp_by(ordering, other)
        if !cmp.nil? && cmp != 0
          return cmp * dir
        end
      end
      id <=> other.id
    end

    def id
      value.fetch("slug", "")
    end

  private

    def cmp_by(ordering, other)
      case ordering
      when :filtered
        (
          applied ? 0 : 1
        ) <=> (
          other.applied ? 0 : 1
        )
      when :count
        count <=> other.count
      when :value
        if value.is_a?(String)
          value.downcase <=> other.value.downcase
        else
          value.fetch("title", "").downcase <=> other.value.fetch("title", "").downcase
        end
      when :"value.slug"
        value.fetch("slug", "") <=> other.value.fetch("slug", "")
      when :"value.title"
        value.fetch("title", "").downcase <=> other.value.fetch("title", "").downcase
      when :"value.link"
        value.fetch("link", "") <=> other.value.fetch("link", "")
      end
    end
  end
end
