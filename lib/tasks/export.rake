require "csv"
require "rack"
require "rummager"

namespace :export do
  desc "Get all results which match the given search.  Set FIELDS to control the exported fields."
  task :search, [:query_string] do |_, args|
    params = Rack::Utils.parse_nested_query(args.query_string)
               .merge("fields" => "content_id,#{ENV.fetch('FIELDS', '')}")
               .map { |k, v| [k, [v]] }.to_h
    search_params = SearchConfig.parse_parameters(params)
    query = search_params.search_config.generate_query_for_params(search_params)
    query[:sort] = %i(document_type _uid)
    fields = search_params.return_fields.uniq
    base_uri = search_params.search_config.base_uri

    CSV.open("export-search.csv", "wb", headers: fields, write_headers: true, force_quotes: true) do |csv|
      ScrollEnumerator.new(
        client: Services.elasticsearch(hosts: base_uri),
        index_names: SearchConfig.content_index_names + [SearchConfig.govuk_index_name],
        search_body: query,
      ) { |hit| hit }.each { |hit| csv << fields.map { |f| present_field(hit["_source"][f]) } }
    end
  end

  def present_field(value)
    if value.is_a? Hash
      value.fetch("slug", value)
    elsif value.is_a? Array
      value.join(",")
    else
      value
    end
  end
end
