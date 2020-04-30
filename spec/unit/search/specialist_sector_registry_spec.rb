require "spec_helper"

RSpec.describe Search::BaseRegistry, "Specialist Sector" do
  before do
    @index = double("elasticsearch index")
    @specialist_sector_registry = described_class.new(@index, sample_field_definitions, "specialist_sector")
  end

  def oil_and_gas
    {
      "link" => "/topic/oil-and-gas/licensing",
      "slug" => "oil-and-gas/licensing",
      "title" => "Licensing",
    }
  end

  it "can fetch sector by slug" do
    allow(@index).to receive(:documents_by_format)
      .with("specialist_sector", anything)
      .and_return([oil_and_gas])
    sector = @specialist_sector_registry["oil-and-gas/licensing"]
    expect(oil_and_gas).to eq(sector)
  end

  it "only required fields are requested from index" do
    expect(@index).to receive(:documents_by_format)
      .with("specialist_sector", sample_field_definitions(%w[link slug title content_id]))
      .and_return([])
    @specialist_sector_registry["oil-and-gas/licensing"]
  end

  it "returns nil if sector not found" do
    allow(@index).to receive(:documents_by_format)
      .with("specialist_sector", anything)
      .and_return([oil_and_gas])
    sector = @specialist_sector_registry["foo"]
    expect(sector).to be_nil
  end

  it "uses 300 second cache lifetime" do
    expect(Search::TimedCache).to receive(:new).with(300, anything)

    described_class.new(@index, sample_field_definitions, "specialist_sector")
  end
end
