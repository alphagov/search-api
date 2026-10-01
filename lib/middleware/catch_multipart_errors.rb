module Middleware
  class CatchMultipartErrors
    def initialize(app)
      @app = app
    end

    def call(env)
      if env["CONTENT_TYPE"]&.include?("multipart/form-data")
        begin
          Rack::Multipart.parse_multipart(env)
        rescue Rack::Multipart::EmptyContentError
          return [
            400,
            { "Content-Type" => "application/json" },
            ["Bad request"],
          ]
        end
      end

      @app.call(env)
    end
  end
end
