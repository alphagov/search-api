require "spec_helper"

RSpec.describe Auth::GdsSso do
  describe ".locate" do
    it "returns a user when request succeeds" do
      user = { "uid" => SecureRandom.uuid,
               "name" => "User",
               "email" => "testuser@example.com" }
      stub_request(:get, %r{/user.json})
        .to_return(body: { "user" => user }.to_json)

      response = described_class.locate("my_token")
      expect(response).to eq(user)
    end

    it "returns nil when a request fails" do
      stub_request(:get, %r{/user.json}).to_return(status: 401)
      response = described_class.locate("my_token")
      expect(response).to be_nil
    end
  end
end
