require 'test/support/test_index_helpers'

class IntegrationTest < Minitest::Test
  include Rack::Test::Methods

  SAMPLE_DOCUMENT_ATTRIBUTES = {
    "title" => "TITLE1",
    "description" => "DESCRIPTION",
    "format" => "local_transaction",
    "link" => "/URL",
    "_type" => "edition",
  }.freeze

  def initialize(args)
    super(args)
  end

  def setup
    # search_config is a global object that has state, so make sure it's reset
    # between tests.
    SearchConfig.instance = SearchConfig.new

    TestIndexHelpers.stub_elasticsearch_settings
  end

  def teardown
    TestIndexHelpers::ALL_TEST_INDEXES.each do |index|
      clean_index_content(index)
    end
  end

  def search_config
    SearchConfig.instance
  end

  def search_server
    search_config.search_server
  end

  def sample_document
    Document.from_hash(SAMPLE_DOCUMENT_ATTRIBUTES, sample_elasticsearch_types)
  end

  def insert_document(index_name, attributes, id: attributes["link"], type: "edition", version: nil)
    version_details =
      if version
        {
          version: version,
          version_type: 'external',
        }
      else
        {}
      end

    id ||= "/test/#{SecureRandom.uuid}"
    attributes['link'] ||= id

    client.create(
      {
        index: index_name,
        type: type,
        id: id,
        body: attributes,
      }.merge(version_details)
    )

    id
  end

  def clean_index_content(index)
    commit_index index

    hits = client.search(index: index, size: 1000)['hits']['hits']
    return if hits.empty?

    client.bulk body: (hits.map { |hit| { delete: { _index: index, _type: hit['_type'], _id: hit['_id'] } } })
    commit_index index
  end

  def commit_document(index_name, attributes, id: attributes["link"], type: "edition")
    insert_document(index_name, attributes, id: id, type: type).tap do
      commit_index(index_name)
    end
  end

  def commit_index(index_name = "mainstream_test")
    client.indices.refresh(index: index_name)
  end

  def app
    Rummager
  end

  def client
    # Set a fairly long timeout to avoid timeouts on index creation on the CI
    # servers
    @client ||= Services::elasticsearch(hosts: ELASTICSEARCH_TESTING_HOST, timeout: 10)
  end

  def parsed_response
    JSON.parse(last_response.body)
  end

  def assert_document_is_in_rummager(document, type: "edition", index: 'mainstream_test')
    retrieved = fetch_document_from_rummager(id: document['link'], index: index)

    assert_equal type, retrieved["_type"]

    retrieved_source = retrieved["_source"]
    document.each do |key, value|
      assert_equal value, retrieved_source[key],
        "Field #{key} should be '#{value}' but was '#{retrieved_source[key]}'"
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
        "mainstream_browse_pages" => "browse/page/#{i}",
        "format" => "answers"
      }
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
    data = attributes.flat_map do |sample_document|
      [
        { index: { _id: sample_document['link'], _type: 'edition' } },
        sample_document,
      ]
    end

    client.bulk(index: index_name, body: data)
    commit_index(index_name)
  end

  def try_remove_test_index(index_name = TestIndexHelpers::DEFAULT_INDEX_NAME)
    TestIndexHelpers.check_index_name!(index_name)

    if client.indices.exists?(index: index_name)
      client.indices.delete(index: index_name)
    end
  end

  def stub_message_payload(example_document, unpublishing: false)
    routing_key = unpublishing ? 'test.unpublish' : 'test.a_routing_key'
    stubs(:message).tap do |message|
      message.stubs(:ack)
      message.stubs(:payload).returns(example_document)
      message.stubs(:delivery_info).returns(routing_key: routing_key)
    end
  end

private

  def populate_content_indexes(params)
    TestIndexHelpers::INDEX_NAMES.each do |index_name|
      add_sample_documents(index_name, params[:section_count])
    end
  end

  def fetch_document_from_rummager(id:, index: 'mainstream_test', type: '_all')
    client.get(
      index: index,
      type: type,
      id: id
    )
  end

  def stubbed_search_config
    search_config = SearchConfig.new
    TestIndexHelpers.stub_elasticsearch_settings(search_config)

    search_config
  end
end
