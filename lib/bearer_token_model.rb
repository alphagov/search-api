require "oauth2"

class BearerTokenModel
  def self.locate(token_string)
    new(token_string).locate
  end

  def initialize(token_string)
    @token_string = token_string
  end

  def locate
    access_token = OAuth2::AccessToken.new(oauth_client, token_string)
    access_token.get("/user.json?client_id=#{oauth_id}").body
  rescue OAuth2::Error => e
    nil
  end

private

  attr_reader :token_string

  def oauth_client
    @oauth_client ||= OAuth2::Client.new(
      oauth_id, oauth_secret, site: Plek.new.external_url_for("signon")
    )
  end

  def oauth_id
    ENV["OAUTH_ID"]
  end

  def oauth_secret
    ENV["OAUTH_SECRET"]
  end
end
