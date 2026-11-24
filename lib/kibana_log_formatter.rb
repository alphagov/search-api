require "csv"
require "random/formatter"

class KibanaLogFormatter
  def initialize(csv_logs_file, gor_traffic_replay_file = "tmp/traffic_replay_#{Time.now.strftime('%Y%m%d%H%M%S')}.gor")
    @csv_logs_file = csv_logs_file
    @gor_traffic_replay_file = gor_traffic_replay_file
  end

  # Yup that's the line separator format https://github.com/buger/goreplay/wiki/Saving-and-Replaying-from-file#file-format
  GOR_LINE_SEPARATOR = "\n🐵🙈🙉\n".freeze

  def save_as_gor
    File.open(@gor_traffic_replay_file, "a") do |f|
      logs = CSV.read(@csv_logs_file, headers: true)
      sorted_logs = logs.sort_by { |log| Time.parse(log["@timestamp"]) }
      sorted_logs.each do |log|
        f.print get_gor_entry(log)
        f.print GOR_LINE_SEPARATOR
      end
    end
  end

private

  def log_timestamp(row)
    (Time.strptime(row["@timestamp"], "%d %b, %Y @ %H:%M:%S.%N").to_r * 1000).to_i.to_s
  end

  def get_gor_entry(log_entry)
    # Protocol header
    # {Protocol Mode} {24 Random Bytes} {timing} {latency}
    # "1" means it is Making a request
    gor_entry = []
    gor_entry << "1 #{Random.hex(12)} #{log_timestamp(log_entry)}000000 0"
    gor_entry << "GET #{log_entry['logjson.request_uri'].strip} HTTP/1.1\r"
    gor_entry << "Host: www.gov.uk\r"

    "#{gor_entry.join("\n")}\n\n"
  end
end
