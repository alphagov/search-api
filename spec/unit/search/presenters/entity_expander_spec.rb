require 'spec_helper'

RSpec.describe 'EntityExpanderTest' do
  # Since expanding is being done in the same way we only have to test one
  # case (organisations). Integration tests cover the rest.
  it "expands_elements_in_document" do
    expandable_target = {
        "slug" => "rail-statistics",
        "link" => "/government/organisations/department-for-transport/series/rail-statistics",
        "title" => "Rail statistics"
    }

    registries = { organisations: { "rail-statistics" => expandable_target } }

    result = Search::EntityExpander.new(registries).new_result(
      { "organisations" => ["rail-statistics"] }
    )

    assert_equal result["organisations"].first, expandable_target
  end
end
