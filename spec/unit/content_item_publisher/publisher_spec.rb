require "spec_helper"

RSpec.describe ContentItemPublisher::Publisher do
  subject(:instance) { described_class.new(finder, timestamp) }

  let(:config_file) { "finders/news_and_communications_finder.yml" }
  let(:finder) { YAML.load_file(File.join(Dir.pwd, "config", config_file)) }
  let(:timestamp) { Time.now.iso8601 }
  let(:logger) { instance_double("Logger") }

  before do
    allow(Logger).to receive(:new).and_return(logger)
  end

  describe "#call" do
    it "throws an error" do
      # See finder_publisher_spec for more extensive tests
      expect {
        instance.call
      }.to raise_error NotImplementedError
    end
  end
end
