class Rummager < Sinatra::Application
  get '/content' do
    raw_result = find_result_by_link(params["link"])
    {
      index: SearchIndices::Index.strip_alias_from_index_name(raw_result['_index']),
      raw_source: raw_result['_source']
    }.to_json
  end

  delete '/content' do
    begin
      require_authentication
      raw_result = find_result_by_link(params["link"])
      delete_result_from_index(raw_result)
      json_result 204, "Deleted the link from search index"
    rescue SearchIndices::IndexLocked
      json_result 423, "The index is locked. Please try again later."
    end
  end

private

  def index
    SearchConfig.default_instance.content_index
  end

  def find_result_by_link(link)
    raw_result = index.get_document_by_link(link)

    unless raw_result
      halt 404, "No document found with link #{link}."
    end

    raw_result
  end

  def delete_result_from_index(raw_result)
    index = search_server.index(raw_result['real_index_name'])
    index.delete(raw_result['_id'])
  end
end
