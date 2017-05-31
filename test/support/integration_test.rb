require 'test/support/test_index_helpers'

class IntegrationTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  SAMPLE_DOCUMENT_ATTRIBUTES = {
    "title" => "TITLE1",
    "description" => "DESCRIPTION",
    "format" => "local_transaction",
    "link" => "/URL"
  }.freeze

  def initialize(args)
    super(args)
  end

  def setup
    TestIndexHelpers.stub_elasticsearch_settings
  end

  def teardown
    TestIndexHelpers::ALL_TEST_INDEXES.each do |index|
      clean_index_content(index)
    end
  end

  def search_config
    app.settings.search_config
  end

  def search_server
    search_config.search_server
  end

  def sample_document
    Document.from_hash(SAMPLE_DOCUMENT_ATTRIBUTES, sample_elasticsearch_types)
  end

  def insert_document(index_name, attributes, type: "edition")
    attributes.stringify_keys!
    type = attributes["_type"] || type
    client.create(
      index: index_name,
      type: type,
      id: attributes['link'],
      body: attributes
    )
  end

  def clean_index_content(index)
    client.delete_by_query(
      index: index,
      body: {
        query: {
          match_all: {}
        }
      }
    )
  end

  def commit_document(index_name, attributes, type: "edition")
    insert_document(index_name, attributes, type: type)
    commit_index(index_name)
  end

  def commit_index(index_name = "mainstream_test")
    client.indices.refresh(index: index_name)
  end

  def app
    Rummager
  end

  def client
    @client ||= Services::elasticsearch(hosts: 'http://localhost:9200')
  end

  def parsed_response
    JSON.parse(last_response.body)
  end

  def assert_document_is_in_rummager(document)
    retrieved = fetch_document_from_rummager(id: document['link'])

    document.each do |key, value|
      assert_equal value, retrieved[key],
        "Field #{key} should be '#{value}' but was '#{retrieved[key]}'"
    end
  end

  def sample_document_attributes(index_name, section_count)
    short_index_name = index_name.sub("_test", "")
    (1..section_count).map do |i|
      title = "Sample #{short_index_name} document #{i}"
      if i % 2 == 1
        title = title.downcase
      end
      fields = {
        "title" => title,
        "link" => "/#{short_index_name}-#{i}",
        "indexable_content" => "Something something important content id #{i}",
      }
      fields["mainstream_browse_pages"] = [i.to_s]
      if i % 2 == 0
        fields["specialist_sectors"] = ["farming"]
      end
      if short_index_name == "government"
        fields["public_timestamp"] = "#{i + 2000}-01-01T00:00:00"
      end
      fields
    end
  end

  def add_sample_documents(index_name, count)
    attributes = sample_document_attributes(index_name, count)
    attributes.each do |sample_document|
      insert_document(index_name, sample_document)
    end

    commit_index(index_name)
  end

  def try_remove_test_index(index_name = TestIndexHelpers::DEFAULT_INDEX_NAME)
    TestIndexHelpers.check_index_name!(index_name)

    if client.indices.exists?(index: index_name)
      client.indices.delete(index: index_name)
    end
  end

private

  def populate_content_indexes(params)
    TestIndexHelpers::INDEX_NAMES.each do |index_name|
      add_sample_documents(index_name, params[:section_count])
    end
  end

  def fetch_raw_document_from_rummager(id:, index: 'mainstream_test', type: '_all')
    client.get(
      index: index,
      type: type,
      id: id
    )
  end

  def fetch_document_from_rummager(id:, index: 'mainstream_test', type: '_all')
    response = client.get(
      index: index,
      type: type,
      id: id
    )
    response['_source']
  end
end
