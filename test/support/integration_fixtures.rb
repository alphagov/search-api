module IntegrationFixtures
  include Fixtures::DefaultMappings

  def sample_document_attributes
    {
      "title" => "TITLE1",
      "description" => "DESCRIPTION",
      "format" => "local_transaction",
      "section" => "life-in-the-uk",
      "link" => "/URL"
    }
  end

  def sample_document
    Document.from_hash(sample_document_attributes, sample_document_types)
  end
end
