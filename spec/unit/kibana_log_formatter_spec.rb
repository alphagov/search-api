require "spec_helper"
require "tempfile"

RSpec.describe KibanaLogFormatter do
  let(:file) { Tempfile.create(%w[logs .csv]) }
  let(:output_gor_file) { Tempfile.create(%w[traffic_replay_ .gor]) }
  let(:input_csv_file) do
    CSV.generate do |csv|
      csv << %w[request_uri timestamp message]
      csv << %w[/api/search.json 2026-06-17T10:00:01+00:00 {"@timestamp":"2026-06-17T10:00:01+00:00","body_bytes_sent":26134}]
      csv << %w[/search/news-and-communications 2026-06-17T10:03:03+00:00 {"@timestamp":"2026-06-17T10:03:03+00:00","body_bytes_sent":439144}]
      csv << %w[/search/all?keywords= 2026-06-17T09:58:20+00:00 {"@timestamp":"2026-06-17T09:58:20+00:00","body_bytes_sent":111202}]
    end
  end
  let(:gor_formatted_first_request) { "1781690401000000000 0\nGET /api/search.json HTTP/1.1\r\nHost: www.gov.uk\r\n\n\n🐵🙈🙉\n" }

  subject(:formatter) { described_class.new(file, output_gor_file) }

  before do
    file.write(input_csv_file)
    file.close
  end

  after do
    File.unlink(output_gor_file.path)
  end

  describe "#save_as_gor" do
    it "formats the output correctly" do
      formatter.save_as_gor
      expect(File.open(output_gor_file.path).read).to include(gor_formatted_first_request)
    end
  end
end
