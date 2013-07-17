require "test_helper"
require "failed_job_worker"
require "config"
require "logging"

class FailedJobWorkerTest < MiniTest::Unit::TestCase
  def test_should_send_to_mailer
    mock_mailer = mock("Mailer")
    mock_mailer.expects(:send_email).with('Job failure', includes("aardvark"))
    Sinatra::Application.settings.expects(:mailer).returns(mock_mailer)
    FailedJobWorker.new.perform({"aardvark" => "horseradish"})
  end

  def test_should_warn_when_no_mailer_configured
    Sinatra::Application.settings.expects(:mailer).returns(nil)
    Logging.logger[FailedJobWorker].expects(:warn)
    FailedJobWorker.new.perform({"aardvark" => "horseradish"})
  end
end
