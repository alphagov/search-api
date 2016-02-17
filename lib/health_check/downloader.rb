require 'time'
require 'open-uri'
require 'fileutils'

module HealthCheck
  class Downloader
    def initialize(options = {})
      @data_dir = options[:data_dir]
      @logger = options[:logger] || Logging.logger[self]
    end

    def download!
      write(
        "#{@data_dir}/search-results.csv",
        fetch_data(url: spreadsheet_url(gid: '1400194374'))
      )
      write(
        "#{@data_dir}/suggestions.csv",
        fetch_data(url: spreadsheet_url(gid: '9'))
      )
    end

  private

    def spreadsheet_url(gid:)
      "https://docs.google.com/spreadsheet/pub?key=0AmD7K4ab1dYrdDR5c2tITTNHRUZqajFTTU8wODAzZ1E&single=true&output=csv&gid=#{gid}"
    end

    def fetch_data(url:)
      data = open(url).read
      @logger.info "Downloaded #{url}"
      data
    end

    def write(filename, data)
      File.open(filename, "wb") do |file|
        file.write(data)
        @logger.info "Wrote #{filename}"
      end
    end
  end
end
