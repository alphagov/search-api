module IndexDocumentsTestHelpers
  # There are quite a few api calls made when expanding/indexing
  # data when topics are updated.

  # Hide the stub requests in this helper
  def stub_calls_for_index_documents_test
    stub_request(:get, "http://publishing-api.dev.gov.uk/v2/content/uuid-1").
      to_return(status: 200, body: { id: 1111, base_path: "/path/1" }.to_json)

    stub_request(:get, "http://publishing-api.dev.gov.uk/v2/content/uuid-2").
      to_return(status: 200, body: { id: 2222, base_path: "/path/2" }.to_json)

    stub_request(:get, "http://publishing-api.dev.gov.uk/v2/content/uuid-3").
      to_return(status: 200, body: { id: 3333, base_path: "/path/3" }.to_json)

    stub_request(:get, "http://localhost:9200/mainstream_test,government_test/_search").
      with(body: {query: {term: {link: "/topic/animal-welfare/pets"}}}.to_json).
      to_return(status: 200, body: pet_topic_search_response_data)

    stub_request(:get, "http://localhost:9200/mainstream_test/edition/%2Ftopic%2Fanimal-welfare%2Fpets").
      to_return(status: 200, body: pets_search_result)

    stub_request(:post, "http://localhost:9200/mainstream_test/_bulk").
      with(body: post_no_specialist_sectors_to_elasticsearch).
      to_return(status: 200, body: no_specialist_sectors_elasticsearch_post_response)

    stub_request(:post, "http://localhost:9200/mainstream_test/_bulk").
      with(body: post_specialist_sectors_to_elasticsearch).
      to_return(status: 200, body: specialist_sectors_post_response)
  end

  def pet_topic_search_response_data
    {
      hits: {
        hits: [
          {
            _index: "mainstream_test-2016-01-04t14:17:28z-00000000-0000-0000-0000-000000000000",
            _type: "edition",
            _id: "/topic/animal-welfare/pets",
            _source: {
              slug: "animal-welfare/pets",
              description: "Info about pets.",
              format: "specialist_sector",
              link: "/topic/animal-welfare/pets",
              title: "Pets",
              _type: "edition",
              _id: "/topic/animal-welfare/pets"
            }
          }
        ]
      }
    }.to_json
  end

  def post_specialist_sectors_to_elasticsearch
    # bulk operation receives multiple JSON objects joined by newlines
    [
      {
        index: {
          _type: "edition",
          _id: "/topic/animal-welfare/pets"
        }
      }.to_json,
      {
        slug: "animal-welfare/pets",
        specialist_sectors: ["/path/1"],
        description: "Info about pets.",
        format: "specialist_sector",
        link: "/topic/animal-welfare/pets",
        title: "Pets",
        _type: "edition",
        _id: "/topic/animal-welfare/pets"
      }.to_json
    ].join("\n")
  end

  def post_no_specialist_sectors_to_elasticsearch
    # bulk operation receives multiple JSON objects joined by newlines
    [
      {
        index: {
          _type: "edition",
          _id: "/topic/animal-welfare/pets"
        }
      }.to_json,
      {
        popularity: "5.6085249579360626e-05",
        slug: "animal-welfare/pets",
        description: "Info about pets.",
        format: "specialist_sector",
        link: "/topic/animal-welfare/pets",
        title: "Pets",
        _type: "edition",
        _id: "/topic/animal-welfare/pets"
      }.to_json
    ].join("\n")
  end

  def no_specialist_sectors_elasticsearch_post_response
    {
      items: [
        {
          index: {
            _index: "mainstream_test-2016-01-04t14:17:28z-00000000-0000-0000-0000-000000000000",
            _type: "edition",
            _id: "/topic/animal-welfare/pets",
            status: 200
          }
        }
      ]
    }.to_json
  end

  def specialist_sectors_post_response
    {
      items: [
        {
          index: {
            _index: "mainstream_test-2016-01-04t14:17:28z-00000000-0000-0000-0000-000000000000",
            _type: "edition",
            _id: "/topic/animal-welfare/pets",
            status: 200
          }
        }
      ]
    }.to_json
  end

  def pets_search_result
    {
      _index: "mainstream_test-2016-01-04t14:17:28z-00000000-0000-0000-0000-000000000000",
      _type: "edition",
      _id: "/topic/animal-welfare/pets",
      found: true,
      _source: {
        slug: "animal-welfare/pets",
        description: "Info about pets.",
        format: "specialist_sector",
        link: "/topic/animal-welfare/pets",
        title: "Pets",
        _type: "edition",
        _id: "/topic/animal-welfare/pets"
      }
    }.to_json
  end
end
