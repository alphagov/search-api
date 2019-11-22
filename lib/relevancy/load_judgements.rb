require "csv"

module Relevancy
  module LoadJudgements
    def self.from_csv(datafile)
      data = []
      last_query = ""
      CSV.foreach(datafile, headers: true) do |row|
        query = (row["query"] || last_query).strip
        score = row["score"]
        content_id = row["content_id"]
        link = row["link"]

        raise "missing query for row '#{row}'" if query.nil?
        raise "missing score for row '#{row}'" if score.nil?
        raise "missing link|content_id for row '#{row}" if content_id.nil? && link.nil?

        data << { rank: score.to_i, content_id: content_id, link: link, query: query }
        last_query = query
      end
      data
    end
  end
end
