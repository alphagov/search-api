class SynonymParser
  def parse(config)
    index_synonyms = Synonyms.new
    search_synonyms = Synonyms.new

    config.each do |synonyms|
      synonyms.each do |k, v|
        if %w(search both).include?(k)
          search_synonyms << v
        end
        if %w(index both).include?(k)
          index_synonyms << v
        end
      end
    end

    [index_synonyms, search_synonyms]
  end

  class Synonyms
    def initialize
      @synonyms = []
    end

    def <<(synonym)
      synonyms << synonym
    end

    def es_config
      # Returns the configuration to pass to elasticsearch to define a filter
      # which applies these synonyms.  Should be passed in the schema under the
      # path `settings.analysis.filter.<filter_name>`.
      {
        type: :synonym,
        synonyms: synonyms
      }
    end

  private

    attr_reader :synonyms
  end
end
