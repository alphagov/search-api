module HealthCheck
  class CheckFileParser
    def initialize(file)
      @file = file
    end

    def checks
      checks = {}

      CSV.parse(@file, headers: true).each do |row|
        begin
          check = SearchCheck.new
          check.tags             = row.fetch("Tags", []).split(",").map(&:strip)
          check.search_term      = row["When I search for..."]
          check.imperative       = row["Then I..."]
          check.path             = row["see..."].sub(%r{https://www.gov.uk}, "")
          check.minimum_rank     = Integer(row["in the top ... results"])
          check.weight = parse_integer_with_comma(row["Monthly searches"]) || 1

          if check.valid?
            if checks.include?(check.uid)
              logger.error("Overwriting duplicate check #{check.uid}")
            end

            checks[check.uid] = check
          else
            logger.error("Skipping invalid or incomplete row: #{row.to_s.chomp}")
          end
        rescue => e
          logger.error("Skipping invalid or incomplete row: #{row.to_s.chomp} because: #{e.message}")
        end
      end
      checks.values
    end

  private

    def parse_integer_with_comma(raw)
      if raw.nil? || raw.strip.empty?
        nil
      else
        Integer(raw.delete(","))
      end
    end

    def logger
      Logging.logger[self]
    end
  end
end
