desc "Lint Ruby"
task :lint do
  sh "bundle exec rubocop"
end
