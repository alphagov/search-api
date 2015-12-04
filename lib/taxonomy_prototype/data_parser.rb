require 'csv'

module TaxonomyPrototype
  class DataParser
    def initialize(taxonomy_data)
      @taxonomy_data = taxonomy_data
    end

    def write_to(file)
      relevant_columns_in(@taxonomy_data).each do |row|
        mapped_to = row[0]
        link = row[1]
        if mapped_to[0..2] == "n/a"
          next
        else
          taxonomy_slug = sluggify(mapped_to)
          file.write("#{taxonomy_slug}\t#{link}\n")
        end
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
