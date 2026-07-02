require "csv"
require "kibana_log_formatter"

namespace :traffic_replay do
  desc "Reformat csv search traffic logs to gor format"
  task :format_logs, [:log_file] do |_, args|
    abort "Missing argument. Usage: rake traffic_replay:format_logs[log_file]" if args.log_file.nil?

    logger.info "Starting reformatting of search traffic logs"

    KibanaLogFormatter.new(args[:log_file]).save_as_gor

    logger.info "Finished reformatting of search traffic logs"
  end
end
