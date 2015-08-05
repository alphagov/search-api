class Rummager < Sinatra::Application
  get '/content' do
    raw_result = find_result_by_link(params["link"])
    { raw_source: raw_result['_source'] }.to_json
  end

  delete '/content' do
    raw_result = find_result_by_link(params["link"])
    delete_result_from_index(raw_result)
    json_result 204, "Deleted the link from search index"
  end

private

  def find_result_by_link(link)
    results = unified_index.raw_search(query: { term: { link: link }}, size: 1)
    raw_result = results['hits']['hits'].first

    unless raw_result
      halt 404, "No document found with link #{link}."
    end

    raw_result
  end

  def delete_result_from_index(raw_result)
    index_name = Elasticsearch::Index.strip_alias_from_index_name(raw_result['_index'])
    index = search_server.index(index_name)
    index.delete(raw_result['_type'], raw_result['_id'])
  end
end
