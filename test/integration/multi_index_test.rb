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

    INDEX_NAMES.each do |index_name|
      try_remove_test_index(index_name)
      if index_name == "government_test"
        add_field_to_mappings("public_timestamp", "date")
      end
      add_field_to_mappings("topics")
      create_test_index(index_name)
      add_sample_documents(index_name, 2)
      commit_index(index_name)
    end
  end

  def teardown
    INDEX_NAMES.each do |index_name|
      clean_index_group(index_name)
    end
  end

  def sample_document_attributes(index_name, count)
    short_index_name = index_name.sub("_test", "")
    (1..count).map do |i|
      fields = {
        "title" => "Sample #{short_index_name} document #{i}",
        "link" => "/#{short_index_name}-#{i}",
        "indexable_content" => "Something something important content",
      }
      fields["section"] = i
      if i % 2 == 0
        fields["topics"] = ["farming"]
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
      post "/#{index_name}/documents", MultiJson.encode(sample_document)
      assert last_response.ok?
    end
  end

  def commit_index(index_name)
    post "/#{index_name}/commit", nil
  end

  def parsed_response
    MultiJson.decode(last_response.body)
  end
end
