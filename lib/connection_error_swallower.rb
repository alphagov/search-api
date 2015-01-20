class ConnectionErrorSwallower < SimpleDelegator
  attr_reader :logger

  def initialize(obj, options = {})
    super(obj)
    @logger = options[:logger] || Logging.logger["ConnectionErrorSwallower"]
    @had_connection_error = false
  end

  def call(*args)
    return nil if @had_connection_error
    super
  rescue Errno::ECONNREFUSED => e
    logger.error(e)
    @had_connection_error = true
    nil
  end
end
