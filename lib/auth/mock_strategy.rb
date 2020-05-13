module Auth
  class MockStrategy < Warden::Strategies::Base
    def authenticate!
      # use same env var as GDS SSO for consistency
      if ENV.key?("GDS_SSO_MOCK_INVALID")
        fail!("Mocking invalid sign in")
      else
        # This is to match the object signon returns for a user
        success!({
          "uid" => "e7def478-c626-4d1b-9a4d-8a31e3ecfa0d",
          "name" => "Mock API User",
          "email" => "mock.user@example.com",
          "permissions" => %w[signin manage_search_indices],
          "organisation_slug" => nil,
          "organisation_content_id" => nil,
          "disabled" => false,
        })
      end
    end
  end
end
