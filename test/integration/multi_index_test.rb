require "integration_test_helper"
require "app"
require "rest-client"

# Base class for tests which depend on having multiple indexes with test data
# set up.
class MultiIndexTest < IntegrationTest
  def setup
    stub_elasticsearch_settings
    create_meta_indexes
    reset_content_indexes_with_content
  end

  def create_meta_indexes
    AUXILIARY_INDEX_NAMES.each do |index|
      create_test_index(index)
    end
  end

  def reset_content_indexes
    INDEX_NAMES.each do |index_name|
      try_remove_test_index(index_name)
      create_test_index(index_name)
    end
  end

  def reset_content_indexes_with_content(params = { section_count: 2 })
    reset_content_indexes
    populate_content_indexes(params)
  end

  def teardown
    clean_test_indexes
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

    commit_index(index_name)
  end

  def insert_document(index_name, attributes)
    attributes.stringify_keys!
    insert_stub_popularity_data(attributes["link"])
    post "/#{index_name}/documents", attributes.to_json
    assert last_response.ok?, "Failed to insert document"
  end

  def commit_document(index_name, attributes)
    insert_document(index_name, attributes)
    commit_index(index_name)
  end

  def commit_index(index_name)
    post "/#{index_name}/commit", nil
  end

  private

  def populate_content_indexes(params)
    INDEX_NAMES.each do |index_name|
      add_sample_documents(index_name, params[:section_count])
    end
  end
end
