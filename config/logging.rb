require "logging"

class PushableLogger
  # Because RestClient uses the '<<' method, rather than the levelled Logger
  # methods, we have to put together a class that'll assign them a level

  def initialize(logger, level)
    @logger, @level = logger, level
  end

  def <<(message)
    @logger.send @level, message
  end
end

Logging.logger.root.add_appenders Logging.appenders.stdout

# If running within a Rakefile, we have the `verbose` option from the `-v`
# command line flag; if running within a Rack app, we have the `$DEBUG` global.
if (respond_to?(:verbose) && verbose) || $DEBUG
  Logging.logger.root.level = :debug
else
  Logging.logger.root.level = :warn
end

RestClient.log = PushableLogger.new(Logging.logger[RestClient], :debug)
