require "test_helper"
require "backends"
require 'active_support/core_ext/hash/keys'

class BackendsTest < Test::Unit::TestCase
  include Fixtures::DefaultMappings

  def test_should_use_custom_mappings_defined_in_elasticsearch_schema
    settings = stub("settings")
    settings.stubs(:backends).returns(load_yaml_fixture('backends.fixture.yml')["development"].symbolize_keys)
    settings.stubs(:elasticsearch_schema).returns(load_yaml_fixture('elasticsearch_schema.fixture.yml'))
    backends = Backends.new(settings)
    assert_equal %w{title topics}, backends[:government].mappings['edition']['properties'].keys
  end
end
