desc "Copies data across two clusters"
task :elasticdump do
  parameters = JSON.parse(
    ENV.fetch("ELASTICDUMP_PARAMETERS"),
    symbolize_names: true,
  )

  ElasticdumpRunner.call(parameters)

  puts "Done"
end
