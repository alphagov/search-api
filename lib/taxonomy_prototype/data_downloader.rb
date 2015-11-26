require 'open-uri'
require 'csv'

module TaxonomyPrototype
  class DataDownloader
    # This class downloads taxonomy data from a specified set of spreadsheets.
    # It assumes the following about each sheet it imports:
    # a) it is stored on Google drive.
    # b) it is 'published' as a single sheet (not the entire document/workbook),
    #    with tab-seperated values.
    # c) it's key and gid are populated in the SHEETS constant.

    class_attribute :cache_location
    self.cache_location = File.dirname(__FILE__) + "/../../data/prototype_taxonomy/import_dataset.csv"

    SHEETS = [
      { :name => "early_years", key: "1zjRy7XKrcroscX4cEqc4gM9Eq0DuVWEm_5wATsolRJY", gid: "1025053831" },
      { :name => "curriculum_content_mapping", key: "1rViQioxz5iu3hGYFldNOJift0PqjX0fYd8LZz07ljd4", gid: "678558707" },
    ]

    def initialize(log_output: Logging.logger(STDOUT))
      @log_output = log_output
      @log_output.level = :info
    end

    def download
      begin
        File.open(self.class.cache_location, "wb") do |file|
          SHEETS.each do |sheet|
            sheet_url = spreadsheet_url(key: sheet[:key], gid: sheet[:gid])
            logger.info "Attempting download of #{sheet[:name]} (#{sheet_url})"
            remote_taxonomy_data = open(sheet_url).read
            logger.info "Downloaded #{sheet[:name]}"

            relevant_columns_in(remote_taxonomy_data).each do |row|
              mapped_to = row[0]
              link = row[1]
              if mapped_to[0..2] == "n/a"
                next
              else
                taxonomy_slug = sluggify(mapped_to)
                file.write("#{taxonomy_slug}\t#{link}\n")
              end
            end
            logger.info "Finished copying #{sheet[:name]}"
          end
        end
      rescue => e
        @log_output.error "Failed to download and merge all taxonomy sheets"
        @log_output.error "Exception: #{e}"
        @log_output.error "#{e.backtrace.join("\n")}"
        File.delete self.class.cache_location if File.exist? self.class.cache_location
      end
    end

private

    def relevant_columns_in(remote_taxonomy_data)
      tsv_data = CSV.parse(remote_taxonomy_data, col_sep: "\t", headers: true)
      desired_columns = ["mapped to", "link"]
      columns_in_data = tsv_data.headers.map { |header| header.downcase }

      if desired_columns.all? { |column_name| columns_in_data.include? column_name }
        tsv_data.values_at(*desired_columns)
      else
        raise ArgumentError, "Column names did not match expected values #{desired_columns}"
      end
    end

    def spreadsheet_url(key: ,gid:)
      "https://docs.google.com/spreadsheets/d/#{key}/pub?gid=#{gid}&single=true&output=tsv"
    end

    # Standardise the appearance of taxonomy labels extracted from the spreadsheets.
    def sluggify(taxonomy_label)
      taxonomy_label.split(', ').map do |taxon|
        taxon.downcase!
        # Turn unwanted chars into hyphen
        taxon.gsub!(/[^a-z0-9\-_]+/, '-')
        # No more than one hyphen in a row.
        taxon.gsub!(/-{2,}/, '-')
        # Remove leading/trailing separator.
        taxon.gsub!(/^-|-$/, '')
        taxon
      end.join(' > ')
    end
  end
end
