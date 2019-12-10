desc "Run govuk-lint with similar params to CI"
task "lint" do
  sh "bundle exec rubocop"
end
