module Fixtures::EntityExtractorStubs
  def stub_entity_extractor(indexable_content = //, entities = [])
    stub_request(:post, "#{Plek.current.find('entity-extractor')}/extract")
      .with(:body => indexable_content)
      .to_return(:status => 200, :body => entities.to_json)
  end
end
