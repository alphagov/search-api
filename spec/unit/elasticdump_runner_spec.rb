require "spec_helper"

RSpec.describe ElasticdumpRunner do
  let(:blue) { "https://blue-cluster.gov.uk" }
  let(:green) { "https://green-cluster.gov.uk" }

  describe ".call" do
    it "builds an instance with the given parameters and calls it" do
      parameters = { input: blue, output: green }
      runner = instance_double(described_class, call: true)

      allow(described_class).to receive(:new).with(parameters).and_return(runner)

      described_class.call(parameters)

      expect(described_class).to have_received(:new).with(parameters)
      expect(runner).to have_received(:call)
    end
  end

  describe "#call" do
    subject(:runner) { described_class.new(parameters) }

    before do
      allow(runner).to receive(:system).and_return(true)
    end

    context "with only required parameters" do
      let(:parameters) { { input: blue, output: green } }

      it "raises if :input is missing" do
        expect { described_class.new(output: green).call }.to raise_error(KeyError)
      end

      it "raises if :output is missing" do
        expect { described_class.new(input: blue).call }.to raise_error(KeyError)
      end

      it "defaults type to 'data' and limit to 1000" do
        runner.call

        expect(runner).to have_received(:system).with(
          "npx", "--yes", "--cache", instance_of(String),
          ElasticdumpRunner::VERSION,
          "--input", blue,
          "--output", green,
          "--type", "data",
          "--limit", 1000,
          "--input-index", SearchConfig.all_index_names.first,
          "--output-index", SearchConfig.all_index_names.first
        )
      end

      it "defaults indices to SearchConfig.all_index_names" do
        runner.call

        SearchConfig.all_index_names.each do |index|
          expect(runner).to have_received(:system).with(
            "npx", "--yes", "--cache", instance_of(String),
            ElasticdumpRunner::VERSION,
            "--input", blue,
            "--output", green,
            "--type", "data",
            "--limit", 1000,
            "--input-index", index,
            "--output-index", index
          )
        end
      end
    end

    context "with explicit overrides" do
      let(:parameters) do
        {
          input: blue,
          output: green,
          type: "mapping",
          limit: 50,
          indices: %w[only_index],
        }
      end

      it "uses the given type, limit and indices instead of the defaults" do
        runner.call

        expect(runner).to have_received(:system).once.with(
          "npx", "--yes", "--cache", instance_of(String),
          ElasticdumpRunner::VERSION,
          "--input", blue,
          "--output", green,
          "--type", "mapping",
          "--limit", 50,
          "--input-index", "only_index",
          "--output-index", "only_index"
        )
      end
    end

    context "when an elasticdump invocation fails" do
      let(:parameters) do
        { input: "http://in", output: "http://out", indices: %w[index_1 index_2] }
      end

      before do
        allow(runner).to receive(:system).and_return(true, false)
      end

      it "aborts the task" do
        expect { runner.call }.to raise_error(SystemExit)
      end

      it "stops processing further indices" do
        expect { runner.call }.to raise_error(SystemExit)
        expect(runner).to have_received(:system).twice
      end
    end

    context "cache directory handling" do
      let(:parameters) { { input: "http://in", output: "http://out", indices: %w[index_1] } }

      it "creates a temporary directory that exists during the run and is removed after" do
        captured_dir = nil
        allow(runner).to receive(:system) do |*args|
          captured_dir = args[3]
          expect(Dir.exist?(captured_dir)).to be true
          true
        end

        runner.call

        expect(captured_dir).not_to be_nil
        expect(Dir.exist?(captured_dir)).to be false
      end

      it "removes the cache directory even when a call fails" do
        allow(runner).to receive(:system).and_return(false)
        dirs = []
        allow(FileUtils).to receive(:remove_entry).and_wrap_original do |original, dir|
          dirs << dir
          original.call(dir)
        end

        expect { runner.call }.to raise_error(SystemExit)

        expect(dirs.size).to eq(1)
        expect(Dir.exist?(dirs.first)).to be false
      end
    end
  end
end
