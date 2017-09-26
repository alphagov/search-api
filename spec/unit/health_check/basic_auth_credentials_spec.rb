require 'spec_helper'

RSpec.describe HealthCheck::BasicAuthCredentials, tags: ['shoulda'] do
  it "be callable with a user:password string" do
    creds = HealthCheck::BasicAuthCredentials.call "bob:horseradish"
    assert_equal "bob", creds.user
    assert_equal "horseradish", creds.password
  end

  it "fail on a malformed string" do
    assert_raises ArgumentError do
      HealthCheck::BasicAuthCredentials.call "spoons"
    end
  end

  it "fail on a nil value" do
    assert_raises ArgumentError do
      HealthCheck::BasicAuthCredentials.call nil
    end
  end

  it "be splattable" do
    stub_receiver = double("receiver")
    expect(stub_receiver).to receive(:call).with("bob", "horseradish")

    creds = HealthCheck::BasicAuthCredentials.call "bob:horseradish"
    stub_receiver.call(*creds)
  end
end
