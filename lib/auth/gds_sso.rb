module Auth
  class GdsSso
    def self.locate(token_string)
      Services.cache.fetch(['api-user-cache', token_string], expires_in: 5.minutes) do
        new(token_string).locate
      end
    end

    def initialize(token_string)
      @token_string = token_string
    end

    def locate
      access_token = OAuth2::AccessToken.new(oauth_client, token_string)
      body = access_token.get("/user.json?client_id=#{CGI.escape(oauth_id)}").body
      JSON.parse(body)["user"]
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
      ENV.fetch("OAUTH_ID", "")
    end

    def oauth_secret
      ENV.fetch("OAUTH_SECRET", "")
    end
  end
end
