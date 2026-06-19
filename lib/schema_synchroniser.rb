class SchemaSynchroniser
  attr_reader :errors

  def initialize(index_group)
    @index = index_group.current
  end

  def call(mappings)
    @errors = @index.sync_mappings(mappings)
  end

  def synchronised_types
    %w[generic-document].difference(@errors.keys)
  end
end
