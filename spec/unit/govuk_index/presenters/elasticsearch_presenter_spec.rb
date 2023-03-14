require "spec_helper"

RSpec.describe GovukIndex::ElasticsearchPresenter do
  it "identifier" do
    payload = generate_random_example(payload: { payload_version: 1 })

    expected_identifier = {
      _type: "generic-document",
      _id: payload["base_path"],
      version: 1,
      version_type: "external",
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

  it "sets the updated_at timestamp" do
    payload = generate_random_example(payload: { payload_version: 1 })
    presenter = elasticsearch_presenter(payload, "help_page")
    expect(presenter.updated_at).not_to be nil
  end

  context "external content" do
    it "is valid if it has a URL" do
      payload = {
        "document_type" => "external_content",
        "details" => {
          "url" => "some URL",
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

  describe "#image_url" do
    let(:default_news_image_url) { "https://www.test.gov.uk/default_news_image.jpg" }
    let(:expanded_links) do
      { "primary_publishing_organisation" => [{
        "details" => { "default_news_image" => { "url" => default_news_image_url } },
      }] }
    end

    it "returns a newslike document's organisation's default news image if it does not have an image" do
      payload = generate_random_example(
        schema: "news_article",
        payload: {
          payload_version: 1,
          document_type: "news_story",
          content_purpose_subgroup: "news",
        },
      )
      payload["details"].delete("image")
      payload["expanded_links"] = expanded_links

      presenter = elasticsearch_presenter(payload, payload["document_type"])
      expect(presenter.image_url).to eq(default_news_image_url)
    end

    it "returns a document's image when it and organisation's default news image are present " do
      image_url = "https://www.test.gov.uk/image.jpg"
      payload = generate_random_example(payload: { payload_version: 1 })
      payload["expanded_links"] = expanded_links
      payload["details"]["image"] = { "url" => image_url }

      presenter = elasticsearch_presenter(payload, payload["document_type"])
      expect(presenter.image_url).to eq(image_url)
    end

    it "returns nil if a document has no image and is not a newslike document" do
      payload = generate_random_example(payload: { payload_version: 1 })
      payload["details"].delete("image")

      presenter = elasticsearch_presenter(payload, payload["document_type"])
      expect(presenter.image_url).to be nil
    end
  end

  def elasticsearch_presenter(payload, type = "aaib_report")
    type_mapper = GovukIndex::DocumentTypeMapper.new(payload)
    allow(type_mapper).to receive(:type).and_return(type)
    described_class.new(payload:, type_mapper:)
  end
end
