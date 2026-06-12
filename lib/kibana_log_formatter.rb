require "csv"
require "random/formatter"

# Yup that's the line separator format https://github.com/buger/goreplay/wiki/Saving-and-Replaying-from-file#file-format
GOR_LINE_SEPARATOR = "\n🐵🙈🙉\n".freeze

kibana_logs_file = ARGV[0]
gor_traffic_replay_file = "tmp/traffic_replay_#{Time.now.strftime('%Y%m%d%H%M%S')}.gor"

def log_timestamp(row)
  DateTime.iso8601(row["message"][15, 25], Date::ENGLAND).strftime("%Q")
end

def save_as_gor(kibana_logs_file, output_file)
  File.open(output_file, "a") do |f|
    CSV.foreach(kibana_logs_file, headers: true) do |row|
      f.print get_gor_entry(row)
      f.print GOR_LINE_SEPARATOR
    end
  end
end

def get_gor_entry(log_entry)
  # Protocol header
  # {Protocol Mode} {24 Random Bytes} {timing} {latency}
  # "1" means it is Making a request
  gor_entry = []
  gor_entry << "1 #{Random.hex(12)} #{log_timestamp(log_entry)}000000 0"
  gor_entry << "GET #{log_entry['request_uri'].strip} HTTP/1.1\r"
  gor_entry << "Host: www.gov.uk\r"

  "#{gor_entry.join("\n")}\n\n"
end

save_as_gor(kibana_logs_file, gor_traffic_replay_file)
