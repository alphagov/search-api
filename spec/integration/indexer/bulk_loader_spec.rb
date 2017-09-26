require 'spec_helper'

RSpec.describe 'BulkLoaderTest', tags: ['integration'] do
  before do
    stub_tagging_lookup
    comparer = double(:comparer)
    comparer.stub(:run).and_return('results' => 'hash')
    Indexer::Comparer.stub(:new).and_return(comparer)
  end

  it "indexes_documents" do
    bulk_load!(
      "title" => "The old title",
      "link" => "/some-link",
    )

    assert_document_is_in_rummager(
      "title" => "The old title",
      "link" => "/some-link",
    )
  end

  it "updates_an_existing_document" do
    commit_document("mainstream_test", {
      "title" => "The old title",
      "link" => "/some-link",
    })

    bulk_load!(
      "title" => "The new title",
      "link" => "/some-link",
    )

    assert_document_is_in_rummager(
      "title" => "The new title",
      "link" => "/some-link",
    )
  end

  it "adds_extra_fields" do
    # We have to insert at least two popularity documents to get a popularity
    # score other than the maximum, because the popularity is based on the rank of the
    # document when ordered by traffic, and the rank is capped at the number of
    # documents in the popularity index.  The actual value we insert here is a
    # rank of 10, but because there are two documents the popularity value we
    # get returned is 1/(2 + popularity_rank_offset), where
    # popularity_rank_offset is a configuration value which is set to 10 by
    # default.
    insert_stub_popularity_data("/some-popular-link")
    insert_stub_popularity_data("/another-example")

    bulk_load!(
      "title" => "The new title",
      "link" => "/some-popular-link",
    )

    assert_document_is_in_rummager(
      "title" => "The new title",
      "link" => "/some-popular-link",
      "popularity" => 1.0 / 12,
    )
  end

private

  def bulk_load!(document)
    bulk_loader = Indexer::BulkLoader.new(
      SearchConfig.instance,
      SearchConfig.instance.default_index_name
    )
    bulk_loader.load_from(StringIO.new(index_payload(document)))
  end

  def index_payload(document)
    index_action = {
      "index" => {
        "_id" => document['link'],
        "_type" => "edition"
      }
    }

    [index_action.to_json, document.to_json].join("\n") + "\n"
  end

  def insert_stub_popularity_data(path)
    document_atts = {
      "path_components" => path,
      "rank_14" => 10,
    }

    client.create(
      index: 'page-traffic_test',
      type: 'page-traffic',
      id: path,
      body: document_atts
    )
    client.indices.refresh(index: 'page-traffic_test')
  end
end
