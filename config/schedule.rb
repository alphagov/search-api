set :output, { error: "log/cron.error.log", standard: "log/cron.log" }
bundler_prefix = ENV.fetch("BUNDLER_PREFIX", "/usr/local/bin/govuk_setenv search-api")
job_type :rake, "cd :path && #{bundler_prefix} bundle exec rake :task :output"

# Sitemap filenames are generated based on the current day and hour. Putting
# this at 10 past gets around any problems that might arise from running just
# before the hour.
every 1.day, at: ENV.fetch("SITEMAP_GENERATION_TIME", "1.10am") do
  rake "sitemap:generate_and_replace"
end
