Logging.logger.root.add_appenders Logging.appenders.stdout

Logging.logger.root.level = if ENV["DEBUG"] || $DEBUG
                              :debug
                            else
                              :info
                            end
