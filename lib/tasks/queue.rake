namespace :jobs do

  task :work do
    base_path = File.join(File.dirname(__FILE__), "../..")
    exec("bundle exec sidekiq -q bulk -q failed -r #{base_path}/bootstrap_worker.rb")
  end
end
