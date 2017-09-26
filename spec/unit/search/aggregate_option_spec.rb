require 'spec_helper'

RSpec.describe Search::AggregateOption do
  it "convert_to_hash" do
    assert_equal(
      { value: { "title" => "Hello" }, documents: 1 },
      described_class.new({ "title" => "Hello" }, 1, true, []).as_hash,
    )
  end

  it "id_is_slug" do
    assert_equal(
      "a_slug",
      described_class.new({ "title" => "Hello", "slug" => "a_slug" }, 1, true, []).id,
    )
  end

  it "compare_by_filtered_first" do
    orderings = [[:filtered, 1]]
    assert(
      described_class.new({}, 0, true, orderings) <
      described_class.new({}, 0, false, orderings)
    )
  end

  it "compare_by_filtered_last" do
    orderings = [[:filtered, -1]]
    assert(
      described_class.new({}, 0, false, orderings) <
      described_class.new({}, 0, true, orderings)
    )
  end

  it "compare_by_count_ascending" do
    orderings = [[:count, 1]]
    assert(
      described_class.new({}, 5, false, orderings) <
      described_class.new({}, 6, false, orderings)
    )
  end

  it "compare_by_count_descending" do
    orderings = [[:count, -1]]
    assert(
      described_class.new({}, 6, false, orderings) <
      described_class.new({}, 5, false, orderings)
    )
  end


  it "compare_by_slug_ascending" do
    orderings = [[:"value.slug", 1]]
    assert(
      described_class.new({ "slug" => "a" }, 0, false, orderings) <
      described_class.new({ "slug" => "b" }, 0, false, orderings)
    )
  end

  it "compare_by_slug_descending" do
    orderings = [[:"value.slug", -1]]
    assert(
      described_class.new({ "slug" => "b" }, 0, false, orderings) <
      described_class.new({ "slug" => "a" }, 0, false, orderings)
    )
  end

  it "compare_by_title_ascending" do
    orderings = [[:"value.title", 1]]
    assert(
      described_class.new({ "title" => "a" }, 0, false, orderings) <
      described_class.new({ "title" => "b" }, 0, false, orderings)
    )
  end

  it "compare_by_title_descending" do
    orderings = [[:"value.title", -1]]
    assert(
      described_class.new({ "title" => "b" }, 0, false, orderings) <
      described_class.new({ "title" => "a" }, 0, false, orderings)
    )
  end

  it "compare_by_title_ignores_case" do
    orderings = [[:"value.title", 1]]
    assert(
      described_class.new({ "title" => "a" }, 0, false, orderings) <
      described_class.new({ "title" => "Z" }, 0, false, orderings)
    )
  end

  it "compare_by_link_ascending" do
    orderings = [[:"value.link", 1]]
    assert(
      described_class.new({ "link" => "a" }, 0, false, orderings) <
      described_class.new({ "link" => "b" }, 0, false, orderings)
    )
  end

  it "compare_by_link_descending" do
    orderings = [[:"value.link", -1]]
    assert(
      described_class.new({ "link" => "b" }, 0, false, orderings) <
      described_class.new({ "link" => "a" }, 0, false, orderings)
    )
  end

  it "compare_by_value" do
    orderings = [[:value, 1]]
    assert(
      described_class.new("a", 0, false, orderings) <
      described_class.new("b", 0, false, orderings)
    )
  end

  it "compare_by_value_with_title" do
    orderings = [[:value, 1]]
    assert(
      described_class.new({ "title" => "a" }, 0, false, orderings) <
      described_class.new({ "title" => "b" }, 0, false, orderings)
    )
  end

  it "fall_back_to_slug_ordering" do
    orderings = [[:count, 1]]
    assert(
      described_class.new({ "slug" => "a" }, 5, false, orderings) <
      described_class.new({ "slug" => "b" }, 5, false, orderings)
    )
  end
end
