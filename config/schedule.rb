set :output, {:error => 'log/cron.error.log', :standard => 'log/cron.log'}
job_type :rake, 'cd :path && /usr/local/bin/govuk_setenv search bundle exec rake :task :output'

# Sitemap filenames are generated based on the current day and hour. Putting
# this at 10 past gets around any problems that might arise from running just
# before the hour.
every 1.day, :at => '1.10am' do
  rake 'sitemap:generate_and_replace'
end
