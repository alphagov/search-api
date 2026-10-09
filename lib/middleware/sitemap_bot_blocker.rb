module Middleware
  class SitemapBotBlocker
    def initialize(app)
      @app = app
    end

    def call(env)
      if env["PATH_INFO"]&.include?("/sitemap") && env["REQUEST_METHOD"] == "POST"
        return [
          400,
          { "Content-Type" => "application/json" },
          ["Bad request"],
        ]
      end

      @app.call(env)
    end
  end
end
