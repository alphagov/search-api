require "spec_helper"

RSpec.describe Indexer::Comparer do
  it "can detect when a record is added" do
    setup_enumerator_response(Indexer::CompareEnumerator::NO_VALUE, { some: "data" })

    comparer = described_class.new(
      "index_a",
      "index_b",
      io: StringIO.new
    )
    outcome = comparer.run
    expect(outcome).to eq({ added_items: 1 })
  end

  it "can detect when a record is removed" do
    setup_enumerator_response({ some: "data" }, Indexer::CompareEnumerator::NO_VALUE)

    comparer = described_class.new(
      "index_a",
      "index_b",
      io: StringIO.new
    )
    outcome = comparer.run
    expect(outcome).to eq({ removed_items: 1 })
  end

  it "can detect when a record has changed" do
    setup_enumerator_response({ data: "old" }, { data: "new" })

    comparer = described_class.new(
      "index_a",
      "index_b",
      io: StringIO.new
    )
    outcome = comparer.run
    expect(outcome).to eq(changed: 1, 'changes: data': 1)
  end

  it "can detect when a record is unchanged" do
    setup_enumerator_response({ data: "some" }, { data: "some" })

    comparer = described_class.new(
      "index_a",
      "index_b",
      io: StringIO.new
    )
    outcome = comparer.run
    expect(outcome).to eq({ unchanged: 1 })
  end

  it "can detect when a record is unchanged apart from ignored fields" do
    setup_enumerator_response({ data: "some", ignore: "me" }, { data: "some" })

    comparer = described_class.new(
      "index_a",
      "index_b",
      ignore: [:ignore],
      io: StringIO.new
    )
    outcome = comparer.run
    expect(outcome).to eq({ unchanged: 1 })
  end

  it "can detect when a record is unchanged apart from default ignored fields" do
    setup_enumerator_response({ data: "some", "popularity" => "100" }, { data: "some" })

    comparer = described_class.new(
      "index_a",
      "index_b",
      io: StringIO.new
    )
    outcome = comparer.run
    expect(outcome).to eq({ unchanged: 1 })
  end

private

  def setup_enumerator_response(left, right)
    allow(Indexer::CompareEnumerator).to receive(:new).with(
      "index_a",
      "index_b",
      satisfy { |c| c.key == Clusters.default_cluster.key },
      {},
      {},
    ).and_return([[left, right]].to_enum)
  end
end
