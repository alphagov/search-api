require 'spec_helper'

RSpec.describe Indexer::BulkLoader do
  it "can_break_iostream_into_batches_of_lines_of_specified_byte_size" do
    input = StringIO.new(%w{a b c d}.join("\n") + "\n")
    loader = described_class.new(double("search config"), double("index name"))
    batches = []
    loader.send(:in_even_sized_batches, input, 4) do |batch|
      batches << batch
    end

    expect(batches).to eq([%W(a\n b\n), %W(c\n d\n)])
  end

  it "line_pairs_are_not_split_if_batch_size_too_small_to_fit_first_pair_of_lines" do
    input = StringIO.new(%w{a b c d}.join("\n") + "\n")
    loader = described_class.new(double("search config"), double("index name"))
    batches = []
    loader.send(:in_even_sized_batches, input, 3) do |batch|
      batches << batch
    end

    expect(batches).to eq([%W(a\n b\n), %W(c\n d\n)])
  end

  it "line_pairs_are_not_split_if_batch_boundary_falls_in_second_pair_of_lines" do
    input = StringIO.new(%w{a b c d e f}.join("\n") + "\n")
    loader = described_class.new(double("search config"), double("index name"))
    batches = []
    loader.send(:in_even_sized_batches, input, 5) do |batch|
      batches << batch
    end

    expect(batches).to eq([%W(a\n b\n c\n d\n), %W(e\n f\n)])
  end
end
