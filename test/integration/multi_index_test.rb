require "integration_test_helper"
require "app"
require "rest-client"

# Base class for tests which depend on having multiple indexes with test data
# set up.
class MultiIndexTest < IntegrationTest

  INDEX_NAMES = ["mainstream_test", "detailed_test", "government_test"]

  def setup
    stub_elasticsearch_settings(INDEX_NAMES)
    app.settings.search_config.stubs(:govuk_index_names).returns(INDEX_NAMES)
    enable_test_index_connections

    @auxiliary_indexes.each do |index|
      create_test_index(index)
    end

    reset_content_indexes
    populate_content_indexes
  end

  def reset_content_indexes
    INDEX_NAMES.each do |index_name|
      try_remove_test_index(index_name)
      create_test_index(index_name)
    end
  end

  def populate_content_indexes
    INDEX_NAMES.each do |index_name|
      add_sample_documents(index_name, 2)
    end
  end

  def teardown
    clean_test_indexes
  end

  def sample_document_attributes(index_name, count)
    short_index_name = index_name.sub("_test", "")
    (1..count).map do |i|
      fields = {
        "title" => "Sample #{short_index_name} document #{i}",
        "link" => "/#{short_index_name}-#{i}",
        "indexable_content" => "Something something important content",
      }
      fields["section"] = ["#{i}"]
      if i % 2 == 0
        fields["specialist_sectors"] = ["farming"]
      end
      if short_index_name == "government"
        fields["public_timestamp"] = "#{i+2000}-01-01T00:00:00"
      end
      fields
    end
  end

  def add_sample_documents(index_name, count)
    attributes = sample_document_attributes(index_name, count)
    attributes.each do |sample_document|
      insert_document(index_name, sample_document)
    end
  end

  def insert_document(index_name, attributes)
    insert_stub_popularity_data(attributes["link"])
    post "/#{index_name}/documents", attributes.to_json
    assert last_response.ok?, "Failed to insert document"
    commit_index(index_name)
  end

  def commit_index(index_name)
    post "/#{index_name}/commit", nil
  end

  def parsed_response
    JSON.parse(last_response.body)
  end
end
