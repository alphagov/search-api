require "spec_helper"

RSpec.describe Search::AggregateOption do
  it "convert to hash" do
    expect(
      value: { "title" => "Hello" }, documents: 1,
    ).to eq(
      described_class.new({ "title" => "Hello" }, 1, true, []).as_hash,
    )
  end

  it "id is slug" do
    expect("a_slug").to eq(
      described_class.new({ "title" => "Hello", "slug" => "a_slug" }, 1, true, []).id,
    )
  end

  it "compare by filtered first" do
    orderings = [[:filtered, 1]]
    expect(
      described_class.new({}, 0, true, orderings),
    ).to be < described_class.new({}, 0, false, orderings)
  end

  it "compare by filtered last" do
    orderings = [[:filtered, -1]]
    expect(
      described_class.new({}, 0, false, orderings),
    ).to be < described_class.new({}, 0, true, orderings)
  end

  it "compare by count ascending" do
    orderings = [[:count, 1]]
    expect(
      described_class.new({}, 5, false, orderings),
    ).to be < described_class.new({}, 6, false, orderings)
  end

  it "compare by count descending" do
    orderings = [[:count, -1]]
    expect(
      described_class.new({}, 6, false, orderings),
    ).to be < described_class.new({}, 5, false, orderings)
  end

  it "compare by slug ascending" do
    orderings = [[:"value.slug", 1]]
    expect(
      described_class.new({ "slug" => "a" }, 0, false, orderings),
    ).to be < described_class.new({ "slug" => "b" }, 0, false, orderings)
  end

  it "compare by slug descending" do
    orderings = [[:"value.slug", -1]]
    expect(
      described_class.new({ "slug" => "b" }, 0, false, orderings),
    ).to be < described_class.new({ "slug" => "a" }, 0, false, orderings)
  end

  it "compare by title ascending" do
    orderings = [[:"value.title", 1]]
    expect(
      described_class.new({ "title" => "a" }, 0, false, orderings),
    ).to be < described_class.new({ "title" => "b" }, 0, false, orderings)
  end

  it "compare by title descending" do
    orderings = [[:"value.title", -1]]
    expect(
      described_class.new({ "title" => "b" }, 0, false, orderings),
    ).to be < described_class.new({ "title" => "a" }, 0, false, orderings)
  end

  it "compare by title ignores case" do
    orderings = [[:"value.title", 1]]
    expect(
      described_class.new({ "title" => "a" }, 0, false, orderings),
    ).to be < described_class.new({ "title" => "Z" }, 0, false, orderings)
  end

  it "compare by link ascending" do
    orderings = [[:"value.link", 1]]
    expect(
      described_class.new({ "link" => "a" }, 0, false, orderings),
    ).to be < described_class.new({ "link" => "b" }, 0, false, orderings)
  end

  it "compare by link descending" do
    orderings = [[:"value.link", -1]]
    expect(
      described_class.new({ "link" => "b" }, 0, false, orderings),
    ).to be < described_class.new({ "link" => "a" }, 0, false, orderings)
  end

  it "compare by value" do
    orderings = [[:value, 1]]
    expect(
      described_class.new("a", 0, false, orderings),
    ).to be < described_class.new("b", 0, false, orderings)
  end

  it "compare by value with title" do
    orderings = [[:value, 1]]
    expect(
      described_class.new({ "title" => "a" }, 0, false, orderings),
    ).to be < described_class.new({ "title" => "b" }, 0, false, orderings)
  end

  it "fall back to slug ordering" do
    orderings = [[:count, 1]]
    expect(
      described_class.new({ "slug" => "a" }, 5, false, orderings),
    ).to be < described_class.new({ "slug" => "b" }, 5, false, orderings)
  end
end
