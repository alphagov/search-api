require "spec_helper"
require "rake"
load "tasks/delete_detailed_index.rake"

RSpec.describe "delete_detailed_index rake task", :integration do
  let(:es_client) do
    Services.elasticsearch
  end

  let(:alias_name) { "detailed" }
  let(:index_name) { "detailed-test-1" }

  before do
    reset_indices!

    es_client.indices.create(index: index_name)
    es_client.indices.put_alias(index: index_name, name: alias_name)
  end

  after do
    reset_indices!
  end

  def run_task
    Rake::Task["delete_detailed_index"].reenable
    Rake::Task["delete_detailed_index"].invoke
  end

  def indices_for_alias
    es_client.indices.get_alias(name: alias_name).keys
  rescue Elasticsearch::Transport::Transport::Errors::NotFound
    []
  end

  def reset_indices!
    es_client.indices.delete(index: indices_for_alias) if indices_for_alias.any?
  end

  it "deletes all indices behind the alias" do
    expect {
      run_task
    }.to change {
      es_client.indices.exists?(index: index_name)
    }.from(true).to(false)
  end
end
