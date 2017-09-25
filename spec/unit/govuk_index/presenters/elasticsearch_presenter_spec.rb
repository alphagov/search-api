require 'spec_helper'

RSpec.describe 'GovukIndex::ElasticsearchPresenterTest' do
  it "identifier" do
    payload = generate_random_example(payload: { payload_version: 1 },
    regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" })

    expected_identifier = {
      _type: payload["document_type"],
      _id: payload["base_path"],
      version: 1,
      version_type: "external"
    }

    presenter = elasticsearch_presenter(payload, "help_page")

    assert_equal expected_identifier, presenter.identifier
  end

  it "raise_validation_error" do
    payload = {}

    presenter = elasticsearch_presenter(payload)

    assert_raises GovukIndex::ValidationError do
      presenter.valid!
    end
  end

  def elasticsearch_presenter(payload, type = "aaib_report")
    GovukIndex::DocumentTypeInferer.any_instance.stubs(:type).returns(type)
    GovukIndex::ElasticsearchPresenter.new(
      payload: payload,
      type_inferer: GovukIndex::DocumentTypeInferer
    )
  end
end
