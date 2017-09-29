require 'spec_helper'

RSpec.describe HealthCheck::BasicAuthCredentials do
  it "be callable with a user:password string" do
    creds = HealthCheck::BasicAuthCredentials.call "bob:horseradish"
    expect("bob").to eq(creds.user)
    expect("horseradish").to eq(creds.password)
  end

  it "fail on a malformed string" do
    expect {
      HealthCheck::BasicAuthCredentials.call "spoons"
    }.to raise_error(ArgumentError)
  end

  it "fail on a nil value" do
    expect {
      HealthCheck::BasicAuthCredentials.call nil
    }.to raise_error(ArgumentError)
  end

  it "be splattable" do
    stub_receiver = double("receiver")
    expect(stub_receiver).to receive(:call).with("bob", "horseradish")

    creds = HealthCheck::BasicAuthCredentials.call "bob:horseradish"
    stub_receiver.call(*creds)
  end
end
