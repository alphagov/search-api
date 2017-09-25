require 'spec_helper'

RSpec.describe 'AggregateOptionTest' do
  it "convert_to_hash" do
    assert_equal(
      { value: { "title" => "Hello" }, documents: 1 },
      Search::AggregateOption.new({ "title" => "Hello" }, 1, true, []).as_hash,
    )
  end

  it "id_is_slug" do
    assert_equal(
      "a_slug",
      Search::AggregateOption.new({ "title" => "Hello", "slug" => "a_slug" }, 1, true, []).id,
    )
  end

  it "compare_by_filtered_first" do
    orderings = [[:filtered, 1]]
    assert(
      Search::AggregateOption.new({}, 0, true, orderings) <
      Search::AggregateOption.new({}, 0, false, orderings)
    )
  end

  it "compare_by_filtered_last" do
    orderings = [[:filtered, -1]]
    assert(
      Search::AggregateOption.new({}, 0, false, orderings) <
      Search::AggregateOption.new({}, 0, true, orderings)
    )
  end

  it "compare_by_count_ascending" do
    orderings = [[:count, 1]]
    assert(
      Search::AggregateOption.new({}, 5, false, orderings) <
      Search::AggregateOption.new({}, 6, false, orderings)
    )
  end

  it "compare_by_count_descending" do
    orderings = [[:count, -1]]
    assert(
      Search::AggregateOption.new({}, 6, false, orderings) <
      Search::AggregateOption.new({}, 5, false, orderings)
    )
  end


  it "compare_by_slug_ascending" do
    orderings = [[:"value.slug", 1]]
    assert(
      Search::AggregateOption.new({ "slug" => "a" }, 0, false, orderings) <
      Search::AggregateOption.new({ "slug" => "b" }, 0, false, orderings)
    )
  end

  it "compare_by_slug_descending" do
    orderings = [[:"value.slug", -1]]
    assert(
      Search::AggregateOption.new({ "slug" => "b" }, 0, false, orderings) <
      Search::AggregateOption.new({ "slug" => "a" }, 0, false, orderings)
    )
  end

  it "compare_by_title_ascending" do
    orderings = [[:"value.title", 1]]
    assert(
      Search::AggregateOption.new({ "title" => "a" }, 0, false, orderings) <
      Search::AggregateOption.new({ "title" => "b" }, 0, false, orderings)
    )
  end

  it "compare_by_title_descending" do
    orderings = [[:"value.title", -1]]
    assert(
      Search::AggregateOption.new({ "title" => "b" }, 0, false, orderings) <
      Search::AggregateOption.new({ "title" => "a" }, 0, false, orderings)
    )
  end

  it "compare_by_title_ignores_case" do
    orderings = [[:"value.title", 1]]
    assert(
      Search::AggregateOption.new({ "title" => "a" }, 0, false, orderings) <
      Search::AggregateOption.new({ "title" => "Z" }, 0, false, orderings)
    )
  end

  it "compare_by_link_ascending" do
    orderings = [[:"value.link", 1]]
    assert(
      Search::AggregateOption.new({ "link" => "a" }, 0, false, orderings) <
      Search::AggregateOption.new({ "link" => "b" }, 0, false, orderings)
    )
  end

  it "compare_by_link_descending" do
    orderings = [[:"value.link", -1]]
    assert(
      Search::AggregateOption.new({ "link" => "b" }, 0, false, orderings) <
      Search::AggregateOption.new({ "link" => "a" }, 0, false, orderings)
    )
  end

  it "compare_by_value" do
    orderings = [[:value, 1]]
    assert(
      Search::AggregateOption.new("a", 0, false, orderings) <
      Search::AggregateOption.new("b", 0, false, orderings)
    )
  end

  it "compare_by_value_with_title" do
    orderings = [[:value, 1]]
    assert(
      Search::AggregateOption.new({ "title" => "a" }, 0, false, orderings) <
      Search::AggregateOption.new({ "title" => "b" }, 0, false, orderings)
    )
  end

  it "fall_back_to_slug_ordering" do
    orderings = [[:count, 1]]
    assert(
      Search::AggregateOption.new({ "slug" => "a" }, 5, false, orderings) <
      Search::AggregateOption.new({ "slug" => "b" }, 5, false, orderings)
    )
  end
end
