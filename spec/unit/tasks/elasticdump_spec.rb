require "spec_helper"
require "rake"

RSpec.describe "elasticdump rake task" do
  let(:task_name) { "elasticdump" }
  let(:task) { Rake::Task[task_name] }
  let(:blue) { "https://blue-cluster.gov.uk" }
  let(:green) { "https://green-cluster.gov.uk" }

  before do
    task.reenable
  end

  subject(:invoke_task) { task.invoke }

  let(:parameters) do
    { input: blue, output: green, indices: %w[index_1] }
  end

  before do
    allow(ElasticdumpRunner).to receive(:call)
    allow(Kernel).to receive(:puts)
  end

  it "parses ELASTICDUMP_PARAMETERS from the environment with symbolized keys" do
    ClimateControl.modify(ELASTICDUMP_PARAMETERS: parameters.to_json) do
      invoke_task
    end

    expect(ElasticdumpRunner).to have_received(:call).with(parameters)
  end

  it "raises if ELASTICDUMP_PARAMETERS is not set" do
    ClimateControl.modify(ELASTICDUMP_PARAMETERS: nil) do
      expect { invoke_task }.to raise_error(KeyError)
    end
  end

  it "raises if ELASTICDUMP_PARAMETERS is not valid JSON" do
    ClimateControl.modify(ELASTICDUMP_PARAMETERS: "not json") do
      expect { invoke_task }.to raise_error(JSON::ParserError)
    end
  end

  it "prints 'Done' after the runner completes" do
    output = capture_stdout do
      ClimateControl.modify(ELASTICDUMP_PARAMETERS: parameters.to_json) do
        invoke_task
      end
    end

    expect(output).to include("Done")
  end

  it "does not print 'Done' if the runner raises" do
    allow(ElasticdumpRunner).to receive(:call).and_raise(StandardError, "boom")

    output = capture_stdout do
      ClimateControl.modify(ELASTICDUMP_PARAMETERS: parameters.to_json) do
        expect { invoke_task }.to raise_error(StandardError, "boom")
      end
    end

    expect(output).to_not include("Done")
  end
end
