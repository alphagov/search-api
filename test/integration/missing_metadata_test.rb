require "integration_test_helper"
require 'missing_metadata/runner'
require 'gds_api/test_helpers/publishing_api_v2'

class MissingMetadataTest < IntegrationTest
  # def test_will_update_data_fields
  #
  #   commit_document(
  #     "mainstream_test",
  #     "link" => '/path/to_page',
  #     "_type" => "edition",
  #   )
  #
  #   runner = MissingMetadata::Runner.new('content_id')
  #   # publishing_api_has_content()
  #   results = runner.retrieve_records_with_missing_value
  #   assert_equal [:a], results
  #   runner.update
  # end
end
