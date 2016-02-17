require "rest-client"
require "logging"

class PushableLogger
  # Because RestClient uses the '<<' method, rather than the levelled Logger
  # methods, we have to put together a class that'll assign them a level

  def initialize(logger, level)
    @logger = logger
    @level = level
  end

  def <<(message)
    @logger.send @level, message
  end
end

Logging.logger.root.add_appenders Logging.appenders.stdout

if ENV['DEBUG'] || $DEBUG
  Logging.logger.root.level = :debug
else
  Logging.logger.root.level = :warn
end

RestClient.log = PushableLogger.new(Logging.logger[RestClient], :debug)
