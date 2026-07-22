# app/services/elasticdump_runner.rb

class ElasticdumpRunner
  VERSION = "elasticdump@6.124.1".freeze

  def self.call(parameters)
    new(parameters).call
  end

  def initialize(parameters)
    @input = parameters.fetch(:input)
    @output = parameters.fetch(:output)
    @type = parameters.fetch(:type, "data")
    @indices = parameters.fetch(:indices, SearchConfig.all_index_names)
    @limit = parameters.fetch(:limit, 1000)
  end

  def call
    cache_dir = Dir.mktmpdir

    begin
      @indices.each do |index|
        success = system(
          "npx",
          "--yes",
          "--cache",
          cache_dir,
          VERSION,
          "--input", @input,
          "--output", @output,
          "--type", @type,
          "--limit", @limit,
          "--input-index", index,
          "--output-index", index
        )

        abort("elasticdump failed") unless success
      end
    ensure
      FileUtils.remove_entry(cache_dir) if Dir.exist?(cache_dir)
    end
  end
end
