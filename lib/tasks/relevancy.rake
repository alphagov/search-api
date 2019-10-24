require "rummager"
require "analytics/overall_ctr"
require "analytics/popular_queries"
require "analytics/query_performance"

namespace :relevancy do
  desc "Show overall click-through-rate for top 3 results and top 10 results"
  task :show_overall_ctr do
    report_overall_ctr
  end

  desc "Show underperforming queries from top 1_000 most popular queries"
  task :show_underperfoming_queries do
    report_query_ctr
  end

  desc "Print the top 1_000 most popular search queries and their view counts"
  task :show_top_queries do
    report_popular_queries
  end

  desc "Send Google Analytics relevancy data to Graphite
  Takes about 10 minutes.
  Requires SEND_TO_GRAPHITE envvar being set"
  task :send_ga_data_to_graphite do
    puts "Sending overall CTR to graphite"
    report_overall_ctr
    puts "Sending viewcounts to graphite"
    report_popular_queries
    puts "Sending query click-through-rates to graphite"
    report_query_ctr
    puts "Finished"
  end
end

def report_overall_ctr
  report(Analytics::OverallCTR.new.call)
end

def report_query_ctr
  report(Analytics::QueryPerformance.new(queries: popular_queries.map { |q| q[0] }).call)
end

def report_popular_queries
  report(popular_queries.map { |(query, viewcount)| ["#{query}.viewcount", viewcount] })
end

def popular_queries
  @popular_queries ||= Analytics::PopularQueries.new.queries
end

def report(stats = [])
  puts "STATS (past 7 days):"
  puts "=================="
  stats.each do |(stat, reading)|
    puts "#{stat.downcase.gsub(' ', '_')}: #{reading}"
    send_to_graphite(stat, reading)
  end
end
