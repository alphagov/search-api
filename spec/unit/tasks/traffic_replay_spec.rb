require "spec_helper"
require "rake"

RSpec.describe "traffic_replay" do
  let(:kibana_log_formatter) { double("KibanaLogFormatter") }
  let(:file_name) { "log_file.csv" }

  before do
    Rake::Task[task_name].reenable
    allow(KibanaLogFormatter).to receive(:new).with(file_name).and_return(kibana_log_formatter)
    allow(kibana_log_formatter).to receive(:save_as_gor)
  end

  describe "format_logs" do
    let(:task_name) { "traffic_replay:format_logs" }

    context "when no log file is provided" do
      it "prints a helpful message and exits" do
        expect {
          Rake::Task[task_name].invoke(nil)
        }.to output("Missing argument. Usage: rake traffic_replay:format_logs[log_file]\n").to_stderr
                                                                                  .and raise_error(SystemExit)
      end
    end

    context "when a log file is provided" do
      it "calls save_as_gor" do
        Rake::Task[task_name].invoke(file_name)

        expect(kibana_log_formatter).to have_received(:save_as_gor)
      end
    end
  end
end
