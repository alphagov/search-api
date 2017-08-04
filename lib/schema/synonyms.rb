class SynonymParser
  def initialize(schema_path)
    @schema_path = schema_path
  end

  def parse
    # Synonyms are specified in "lucene" syntax, which is a set of lines, each
    # of which holds comma separated lists of synonyms, and optionally a "=>"
    # symbol.
    #
    # See config/schema/README.md for more details.

    synonym_rows = load_synonyms_yaml["synonyms"]
    index_synonyms = []
    search_synonyms = []

    synonym_rows.each_with_index { |row, index|
      if row.include? "=>"
        search_group, index_group = row.split('=>', 2).map { |group|
          group.split(',').map(&:strip)
        }
      else
        search_group = index_group = row.split(',').map(&:strip)
      end
      synonym_term = "!S#{index}"
      index_synonyms << [index_group, synonym_term]
      search_synonyms << [search_group, synonym_term]
    }

    [Synonyms.new(index_synonyms), Synonyms.new(search_synonyms)]
  end

private

  def load_synonyms_yaml
    YAML.load_file(File.join(@schema_path, "synonyms.yml"))
  end

  class Synonyms
    def initialize(synonyms)
      @synonyms = synonyms
    end

    def es_config
      # Returns the configuration to pass to elasticsearch to define a filter
      # which applies these synonyms.  Should be passed in the schema under the
      # path `settings.analysis.filter.<filter_name>`.
      {
        type: :synonym,
        synonyms: @synonyms.map { |group, term|
          "#{group.join(",")}=>#{term}"
        },
      }
    end

    def protwords_config
      # Returns the configuration to pass to elasticsearch to define a filter
      # which marks the terms generated from the synonym matchine process as
      # "keywords".  This prevents them being stemmed, and is required if there
      # is a stemming filter following the synonym filter in the analysis chain.
      {
        type: :keyword_marker,
        keywords: @synonyms.map { |_, term| term }
      }
    end
  end
end
