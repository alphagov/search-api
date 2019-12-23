require "csv"

module LearnToRank
  module LoadSearchQueries
    def self.from_csv(datafile)
      queries = {}
      CSV.foreach(datafile, headers: true) do |row|
        # Todo change the column names in the query
        query = row["searchTerm"].strip
        queries[query] ||= []
        queries[query] << {
          link: row["link"],
          rank: row["avg_rank"],
          views: row["views"],
          clicks: row["clicks"],
        }
      end
      queries
    end
  end
end
