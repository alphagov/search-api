require "test_helper"
require "ses_mailer"

class SESMailerTest < MiniTest::Unit::TestCase
  def test_should_have_recipient_and_sender
    mock_ses = mock("SES")
    AWS::SES::Base.expects(:new).with(:aws_config).returns(mock_ses)
    mailer = SESMailer.new(
      :aws_config,
      to: "foo@example.com",
      from: "bar@example.com"
    )

    mock_ses.expects(:send_email).with(has_entries(
      to: "foo@example.com",
      from: "bar@example.com"
    ))

    mailer.send_email(:subject, :body)
  end

  def test_should_prepend_subject
    mock_ses = mock("SES")
    AWS::SES::Base.expects(:new).with(:aws_config).returns(mock_ses)
    mailer = SESMailer.new(
      :aws_config,
      subject: "[Stuff and things]"
    )

    mock_ses.expects(:send_email).with(has_entry(
      :subject, "[Stuff and things] Something happened"
    ))

    mailer.send_email("Something happened", :body)
  end

  def test_should_send_body
    mock_ses = mock("SES")
    AWS::SES::Base.expects(:new).with(:aws_config).returns(mock_ses)
    mailer = SESMailer.new(:aws_config, {})

    mock_ses.expects(:send_email).with(has_entry(
      :text_body, "BODY BODY BODY"
    ))

    mailer.send_email(:subject, "BODY BODY BODY")
  end
end
