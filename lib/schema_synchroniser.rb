class SchemaSynchroniser
  attr_reader :errors

  def initialize(index_group)
    @index = index_group.current
  end

  def call
    @errors = @index.sync_mappings
  end

  def synchronised_types
    @index.mappings.keys.difference(@errors.keys)
  end
end
