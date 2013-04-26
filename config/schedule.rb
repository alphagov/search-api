set :output, {:error => 'log/cron.error.log', :standard => 'log/cron.log'}
job_type :rake, 'cd :path && /usr/local/bin/govuk_setenv search bundle exec rake :task'

every 1.day, :at => '1.00am' do
  rake 'sitemap:generate_and_replace'
end
