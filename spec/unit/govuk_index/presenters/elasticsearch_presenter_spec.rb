require 'spec_helper'

RSpec.describe GovukIndex::ElasticsearchPresenter do
  it "identifier" do
    payload = generate_random_example(payload: { payload_version: 1 })

    expected_identifier = {
      _type: payload["document_type"],
      _id: payload["base_path"],
      version: 1,
      version_type: "external"
    }

    presenter = elasticsearch_presenter(payload, "help_page")

    expect(expected_identifier).to eq(presenter.identifier)
  end

  it "raise UnknownDocumentTypeError if the document_type does not have a valid mapping" do
    payload = generate_random_example(payload: { payload_version: 1 })
    presenter = elasticsearch_presenter(payload, nil)

    expect {
      presenter.identifier
    }.to raise_error(GovukIndex::UnknownDocumentTypeError)
  end

  it "is invalid if the base_path is missing" do
    payload = {}

    presenter = elasticsearch_presenter(payload)

    expect {
      presenter.valid!
    }.to raise_error(GovukIndex::NotIdentifiable)
  end

  context "external content" do
    it "is valid if it has a URL" do
      payload = {
        "document_type" => "external_content",
        "details" => {
          "url" => "some URL"
        },
      }

      presenter = elasticsearch_presenter(payload)

      presenter.valid!
    end

    it "is invalid if the URL is missing" do
      payload = {
        "document_type" => "external_content",
        "details" => {},
      }

      presenter = elasticsearch_presenter(payload)

      expect {
        presenter.valid!
      }.to raise_error(GovukIndex::MissingExternalUrl)
    end
  end

  def elasticsearch_presenter(payload, type = "aaib_report")
    type_mapper = GovukIndex::DocumentTypeMapper.new(payload)
    allow(type_mapper).to receive(:type).and_return(type)
    described_class.new(payload: payload, type_mapper: type_mapper)
  end
end
