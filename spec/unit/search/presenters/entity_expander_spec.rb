require "spec_helper"

RSpec.describe Search::EntityExpander do
  # Since expanding is being done in the same way we only have to test one
  # case (organisations). Integration tests cover the rest.
  it "expands elements in document" do
    expandable_target = {
        "slug" => "rail-statistics",
        "link" => "/government/organisations/department-for-transport/series/rail-statistics",
        "title" => "Rail statistics"
    }

    registries = { organisations: { "rail-statistics" => expandable_target } }

    result = described_class.new(registries).new_result(
      { "organisations" => ["rail-statistics"] }
    )

    expect(result["organisations"].first).to eq(expandable_target)
  end
end
