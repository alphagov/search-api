require 'test_helper'

class CombinedIndexSchemaTest < Minitest::Test
  def setup
    @base_uri = URI.parse("http://example.com:9200")
    @search_config = SearchConfig.new
    @index_names = @search_config.content_index_names
    @combined_schema = CombinedIndexSchema.new(@index_names, @search_config.schema_config)
  end

  def test_basic_field_definitions
    # The title and public_timestamp fields are defined in the
    # base_elasticsearch_type, so are available in all documents holding content.
    assert_equal "searchable_sortable_text", @combined_schema.field_definitions["title"].type.name
    assert_equal "searchable_text", @combined_schema.field_definitions["description"].type.name
    assert_equal "date", @combined_schema.field_definitions["public_timestamp"].type.name
  end

  def test_merged_field_definitions
    # The location field is defined in both the
    # international_development_fund document type, and in the
    # european_structural_investment_fund document type, with different
    # expanded_search_result_fields.  Check that expansion values from both lists are present.
    locations = @combined_schema.field_definitions["location"].expanded_search_result_fields
    assert locations.include?({ "label" => "Afghanistan", "value" => "afghanistan" })
    assert locations.include?({ "label" => "North East", "value" => "north-east" })
  end

  def test_allowed_filter_fields
    refute @combined_schema.allowed_filter_fields.include? "title"
    assert @combined_schema.allowed_filter_fields.include? "organisations"
  end
end
