require 'spec_helper'

RSpec.describe 'ElasticsearchIndexGroupTest', tags: ['integration'] do
  before do

    @group_name = "mainstream_test"
    TestIndexHelpers.clean_index_group(@group_name)

    @index_group = search_server.index_group(@group_name)
  end

  after do
    # Recreate index deleted by tests.
    # Other integration tests rely on all the test indexes being present.
    # Also ensures there are no missing aliases in the test indexes.
    index = @index_group.create_index
    @index_group.switch_to(index)
  end

  it "should_create_index" do
    assert @index_group.index_names.empty?
    index = @index_group.create_index

    assert_equal 1, @index_group.index_names.count
    assert_equal index.index_name, @index_group.index_names[0]
    assert_equal(
      SearchConfig.instance.search_server.schema.elasticsearch_mappings("mainstream"),
      index.mappings
    )
  end

  it "should_alias_index" do
    index = @index_group.create_index
    @index_group.switch_to(index)

    assert_equal index.real_name, @index_group.current.real_name
  end

  it "should_switch_index" do
    old_index = @index_group.create_index
    @index_group.switch_to(old_index)

    new_index = @index_group.create_index
    @index_group.switch_to(new_index)

    assert_equal new_index.real_name, @index_group.current.real_name
  end

  it "should_clean_indices" do
    @index_group.create_index
    @index_group.switch_to(@index_group.create_index)

    assert_equal 2, @index_group.index_names.count
    @index_group.clean
    assert_equal 1, @index_group.index_names.count
  end
end
