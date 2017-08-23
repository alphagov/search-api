require 'test_helper'

class GovukIndex::ElasticsearchPresenterTest < Minitest::Test
  def test_identifier
    payload = generate_random_example(payload: { payload_version: 1 })

    expected_identifier = {
      _type: payload["document_type"],
      _id: payload["base_path"],
      version: 1,
      version_type: "external"
    }

    presenter = elasticsearch_presenter(payload, "help_page")

    assert_equal expected_identifier, presenter.identifier
  end

  def test_raise_validation_error
    payload = {}

    presenter = elasticsearch_presenter(payload)

    assert_raises GovukIndex::ValidationError do
      presenter.valid!
    end
  end

  def elasticsearch_presenter(payload, type = "aaib_report")
    GovukIndex::ElasticsearchPresenter.new(
      payload: payload,
      type: type
    )
  end
end
