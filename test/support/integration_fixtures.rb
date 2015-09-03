module IntegrationFixtures
  include Fixtures::DefaultMappings

  SAMPLE_DOCUMENT_ATTRIBUTES = {
    "title" => "TITLE1",
    "description" => "DESCRIPTION",
    "format" => "local_transaction",
    "link" => "/URL"
  }

  def sample_document
    Document.from_hash(SAMPLE_DOCUMENT_ATTRIBUTES, sample_document_types)
  end
end
