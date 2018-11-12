require 'spec_helper'

RSpec.describe Search::WorldLocationsRegistry do
  subject(:registry) { described_class.new }

  let(:slug) { 'privet-drive' }

  it "will fetch an expanded world location by slug" do
    fetched_document = registry[slug]
    expect(fetched_document).to eq({
      'title' => 'Privet Drive',
      'slug' => slug
    })
  end

  it "will not fetch a world_location by content_id" do
    expect {
      registry.by_content_id('example-id')
    }.to raise_error(NotImplementedError)
  end

  it "will return all expanded world locations" do
    expect(registry.all).to contain_exactly(
      {
        "slug" => "hogwarts",
        "title" => "Hogwarts"
      },
      {
        "slug" => "privet-drive",
        "title" => "Privet Drive"
      },
      {
       "slug" => "diagon-alley",
       "title" => "Diagon Alley"
      }
    )
  end
end
