namespace :router do
  task :router_environment do
    require 'plek'
    require 'gds_api/router'

    @router_api = GdsApi::Router.new(Plek.current.find('router-api'))
    @app_id = 'rummager'
  end

  task :register_backend => :router_environment do
    url = Plek.current.find(@app_id, :force_http => true) + "/"
    puts "Registering #{@app_id} application against #{url}"
    @router_api.add_backend @app_id, url
  end

  task :register_routes => [ :router_environment ] do
    [
      %w(/sitemap.xml exact),
      %w(/sitemaps prefix),
    ].each do |path, type|
      begin
        puts "Registering #{type} route #{path}"
        @router_api.add_route path, type, @app_id, :skip_commit => true
      rescue => e
        puts "Error registering route: #{e.message}"
        raise
      end
    end
    @router_api.commit_routes
  end

  desc "Register sitemap routes with the router"
  task :register => [ :register_backend, :register_routes ]
end
