require "yaml"
require "aws/ses"

# Based on Rack::MailExceptions
class ExceptionMailer
  def initialize(app, aws_config, options)
    @app = app
    @ses = AWS::SES::Base.new(aws_config)
    @to = options[:to]
    @from = options[:from]
  end

  def call(env)
    status, headers, body =
      begin
        @app.call(env)
      rescue => boom
        send_notification boom, env
        raise
      end
    send_notification env['mail.exception'], env if env['mail.exception']
    [status, headers, body]
  end

  private

  def send_notification(exception, env)
    @ses.send_email(
      to: @to,
      source: @from,
      subject: "[Rummager exception] #{exception.message}",
      text_body: mail_body(exception, env)
    )
  end

  def mail_body(exception, env)
    parts = []
    env_string = env.to_a.
      sort{|a,b| a.first <=> b.first}.
      map{ |k,v| "%-25s%p" % [k+':', v] }.
      join("\n  ")

    parts << <<-EOS
A #{exception.class.to_s} occured: #{exception.to_s}

===================================================================
Rack Environment:
===================================================================

  PID: #{$$}
  PWD: #{Dir.getwd}

  #{env_string}
EOS

    if body = extract_body(env)
      parts << <<-EOS
===================================================================
Request Body:
===================================================================

#{body.gsub(/^/, '  ')}
EOS
    end

    if exception.respond_to?(:backtrace)
      parts << <<-EOS
===================================================================
Backtrace:
===================================================================

#{exception.backtrace.join("\n  ")}
EOS
    end

    parts.map(&:strip).join("\n\n")
  end

  def extract_body(env)
    if io = env['rack.input']
      io.rewind if io.respond_to?(:rewind)
      io.read
    end
  end
end
