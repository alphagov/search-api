Logging.logger.root.add_appenders Logging.appenders.stdout

if ENV["DEBUG"] || $DEBUG
  Logging.logger.root.level = :debug
else
  Logging.logger.root.level = :info
end
