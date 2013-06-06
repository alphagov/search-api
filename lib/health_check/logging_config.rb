Logging.init :debug, :info, :warn, :pass, :fail, :error, :fatal
Logging.color_scheme('bright',
  :levels => {
    :pass  => :green,
    :fail  => :red,
    :error => :red,
    :fatal => [:white, :on_red]
  },
  :date => :blue,
  :logger => :cyan,
  :message => :magenta
)
Logging.appenders.stdout(
  'stdout',
  :layout => Logging.layouts.pattern(
    :pattern => '%-5l %m\n',
    :color_scheme => 'bright'
  )
)
Logging.logger.root.appenders = Logging.appenders.stdout
Logging.logger.root.level = :info
