require "spec_helper"

RSpec.describe Cache do
  it "stores a value" do
    described_class.get("mykey") { 5 }

    expect(described_class.get("mykey")).to eq(5)
  end
  it "sets the value once" do
    described_class.get("mykey") { 5 }
    described_class.get("mykey") { 3 }
    expect(described_class.get("mykey")).to eq(5)
  end
  it "does not evaluate the second time if the resulting value is nil" do
    computation = double("computation", compute: nil)
    described_class.get("mykey") { computation.compute }
    described_class.get("mykey") { computation.compute }
    expect(computation).to have_received(:compute).once
  end
  it "clears the cache" do
    described_class.get("mykey") { 5 }
    described_class.clear
    described_class.get("mykey") { 3 }
    expect(described_class.get("mykey")).to eq(3)
  end
end
