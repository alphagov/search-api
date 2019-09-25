require "spec_helper"

RSpec.describe "ElasticsearchIndexGroupTest" do
  before do
    allow(Clusters).to receive(:active).and_return([Clusters.default_cluster])
    @group_name = "government_test"
    IndexHelpers.clean_index_group(@group_name)

    @index_group = search_server.index_group(@group_name)
  end

  after do
    # Recreate index deleted by tests.
    # Other integration tests rely on all the test indexes being present.
    # Also ensures there are no missing aliases in the test indexes.
    index = @index_group.create_index
    @index_group.switch_to(index)
  end

  it "should create index" do
    expect(@index_group.index_names).to be_empty
    index = @index_group.create_index

    expect(@index_group.index_names.count).to eq(1)
    expect(index.index_name).to eq(@index_group.index_names[0])
    expect(
      SearchConfig.default_instance.search_server.schema.elasticsearch_mappings("government")
    ).to eq(index.mappings)
  end

  it "should alias index" do
    index = @index_group.create_index
    @index_group.switch_to(index)

    expect(index.real_name).to eq(@index_group.current.real_name)
  end

  it "should switch index" do
    old_index = @index_group.create_index
    @index_group.switch_to(old_index)

    new_index = @index_group.create_index
    @index_group.switch_to(new_index)

    expect(new_index.real_name).to eq(@index_group.current.real_name)
  end

  it "should clean indices" do
    @index_group.create_index
    @index_group.switch_to(@index_group.create_index)

    expect(@index_group.index_names.count).to eq(2)
    @index_group.clean
    expect(@index_group.index_names.count).to eq(1)
  end
end
