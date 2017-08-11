require 'test_helper'

module HealthCheck
  class BasicAuthCredentialsTest < ShouldaUnitTestCase
    should "be callable with a user:password string" do
      creds = BasicAuthCredentials.call "bob:horseradish"
      assert_equal "bob", creds.user
      assert_equal "horseradish", creds.password
    end

    should "fail on a malformed string" do
      assert_raises ArgumentError do
        BasicAuthCredentials.call "spoons"
      end
    end

    should "fail on a nil value" do
      assert_raises ArgumentError do
        BasicAuthCredentials.call nil
      end
    end

    should "be splattable" do
      stub_receiver = stub("receiver") do
        expects(:call).with("bob", "horseradish")
      end
      creds = BasicAuthCredentials.call "bob:horseradish"
      stub_receiver.call(*creds)
    end
  end
end
