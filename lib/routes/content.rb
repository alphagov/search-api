class Rummager < Sinatra::Application
  get "/content" do
    raw_result = find_result_by_link(params["link"])
    {
      index: SearchIndices::Index.strip_alias_from_index_name(raw_result["_index"]),
      raw_source: raw_result["_source"]
    }.to_json
  end

  delete "/content" do
    begin
      require_authentication
      Clusters.active.map do |cluster|
        search_config = SearchConfig.instance(cluster)
        raw_result = find_result_by_link(params["link"], search_config)
        index = search_config.search_server.index(raw_result["real_index_name"])
        index.delete(raw_result["_id"])
      end

      json_result 204, "Deleted the link from search index"
    rescue SearchIndices::IndexLocked
      json_result 423, "The index is locked. Please try again later."
    end
  end

private

  def find_result_by_link(link, search_config = SearchConfig.default_instance)
    raw_result = search_config.content_index.get_document_by_link(link)

    unless raw_result
      halt 404, "No document found with link #{link}."
    end

    raw_result
  end
end
