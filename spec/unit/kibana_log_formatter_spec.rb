require "spec_helper"
require "tempfile"

RSpec.describe KibanaLogFormatter do
  subject(:formatter) { described_class.new(file, output_gor_file) }

  let(:file) { Tempfile.create(%w[logs .csv]) }
  let(:output_gor_file) { Tempfile.create(%w[traffic_replay_ .gor]) }
  let(:input_csv_file) do
    CSV.generate do |csv|
      csv << %w[@timestamp logjson.request_uri message]
      csv << ["17 Jun, 2026 @ 10:00:01.305", "/api/search.json", '{"@timestamp":"2026-06-17T10:00:01+00:00","body_bytes_sent":26134}']
      csv << ["17 Jun, 2026 @ 10:03:03.995", "/search/news-and-communications", '{"@timestamp":"2026-06-17T10:03:03+00:00","body_bytes_sent":439144}']
      csv << ["17 Jun, 2026 @ 09:58:20.222", "/search/all?keywords=", '{"@timestamp":"2026-06-17T09:58:20+00:00","body_bytes_sent":111202}']
    end
  end
  let(:gor_formatted_first_request) { "1 7f83aa1e10c7a2d02f87f63d 1781690300222000000 0\nGET /search/all?keywords= HTTP/1.1\r\nHost: www.gov.uk\r\n\n\n🐵🙈🙉\n" }

  before do
    file.write(input_csv_file)
    file.close
    allow(Random).to receive(:hex).with(12).and_return("7f83aa1e10c7a2d02f87f63d")
  end

  after do
    File.unlink(output_gor_file.path)
  end

  describe "#save_as_gor" do
    it "formats the output correctly" do
      formatter.save_as_gor
      expect(File.open(output_gor_file.path).read).to start_with(gor_formatted_first_request)
    end

    it "sorts the logs by timestamp" do
      formatter.save_as_gor
      expect(File.open(output_gor_file.path).read).to match(/keywords.*api.*communications/m)
    end
  end
end
