require "aws/ses"

class SESMailer
  def initialize(aws_config, options)
    @ses = AWS::SES::Base.new(aws_config)

    @to = options[:to]
    @from = options[:from]
    @subject_prefix = options[:subject] || "[Exception]"
  end

  def send_email(subject, body)
    @ses.send_email(
      to: @to,
      from: @from,
      subject: "#{@subject_prefix} #{subject}",
      text_body: body
    )
  end
end
