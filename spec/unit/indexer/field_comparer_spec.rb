RSpec.describe Indexer::GovukIndexFieldComparer do
  it "identifies unchanged content" do
    is_same = described_class.new.call("/some/id", "title", "some text", "some text")
    expect(is_same).to be true
  end

  it "identifies unchanged arrays of content" do
    is_same = described_class.new.call(
      "/some/id",
      "title",
      %w[value1 value2 value3],
      %w[value1 value2 value3],
    )
    expect(is_same).to be true
  end

  it "identifies changed content" do
    is_same = described_class.new.call("/some/id", "title", "some text", "other text")
    expect(is_same).to be false
  end

  it "identifies changes in arrays" do
    is_same = described_class.new.call(
      "/some/id",
      "title",
      %w[value1 value2 value3],
      %w[value1 other_value2 value3],
    )
    expect(is_same).to be false
  end

  it "identifies items added to arrays as changed" do
    is_same = described_class.new.call(
      "/some/id",
      "title",
      %w[value1 value2],
      %w[value1 value2 value3],
    )
    expect(is_same).to be false
  end

  it "identifies items removed from arrays as changed" do
    is_same = described_class.new.call(
      "/some/id",
      "title",
      %w[value1 value2 value3],
      %w[value1 value2],
    )
    expect(is_same).to be false
  end

  it "identifies removed content" do
    is_same = described_class.new.call("/some/id", "title", "some text", nil)
    expect(is_same).to be false
  end

  # We don't mind if the new search index includes additional fields
  it "ignores added content" do
    is_same = described_class.new.call("/some/id", "title", nil, "some text")
    expect(is_same).to be true
  end

  it "ignores differences in apostrophes" do
    is_same = described_class.new.call(
      "/some/id",
      "title",
      "What the government's doing about pigs' and micropigs' welfare",
      "What the government‘s doing about pigs' and micropigs’ welfare",
    )
    expect(is_same).to be true
  end

  it "treats new empty arrays like missing values in old content" do
    comparer = described_class.new

    is_same = comparer.call("/some/id", "organisations", nil, [])

    expect(is_same).to be true
    expect(comparer.stats["AddedValue: organisations"]).to eq 0
  end
end
