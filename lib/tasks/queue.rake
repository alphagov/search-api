namespace :jobs do
  desc "Start Sidekiq workers"
  task :work do
    exec("bundle exec sidekiq -C ./config/sidekiq.yml")
  end
end
