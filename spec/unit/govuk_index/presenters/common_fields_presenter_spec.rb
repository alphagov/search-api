require 'spec_helper'

RSpec.describe 'GovukIndex::ElasticsearchPresenterTest' do
  before do
    @popularity_lookup = double(:popularity_lookup)
    Indexer::PopularityLookup.stub(:new).and_return(@popularity_lookup)
    @popularity_lookup.stub(:lookup_popularities).and_return({})

    @directly_mapped_fields = %w(
      content_id
      description
      email_document_supertype
      government_document_supertype
      navigation_document_supertype
      publishing_app
      rendering_app
      title
      user_journey_document_supertype
    )
  end

  it "directly_mapped_fields" do
    payload = generate_random_example(
      payload: { expanded_links: {} },
      excluded_fields: ["withdrawn_notice"],
      regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" },
    )

    presenter = common_fields_presenter(payload)

    @directly_mapped_fields.each do |field|
      assert_equal presenter.public_send(field), payload[field]
    end
  end

  it "non_directly_mapped_fields" do
    defined_fields = {
      base_path: "/some/path",
      details: { body: "We love cheese" },
      expanded_links: {},
    }

    payload = generate_random_example(
      payload: defined_fields,
      excluded_fields: ["withdrawn_notice"],
      regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" }
    )

    presenter = common_fields_presenter(payload)

    assert_equal presenter.format, payload["document_type"]
    assert_equal presenter.is_withdrawn, false
    assert_equal presenter.link, payload["base_path"]
  end

  it "withdrawn_when_withdrawn_notice_present" do
    payload = {
      "base_path" => "/some/path",
      "withdrawn_notice" => {
        "explanation" => "<div class=\"govspeak\"><p>test 2</p>\n</div>",
        "withdrawn_at" => "2017-08-03T14:02:18Z"
      }
    }

    presenter = common_fields_presenter(payload)

    assert_equal presenter.is_withdrawn, true
  end

  it "popularity_when_value_is_returned_from_lookup" do
    payload = { "base_path" => "/some/path" }

    popularity = 0.0125356

    expect(Indexer::PopularityLookup).to receive(:new).with('govuk_index', SearchConfig.instance).and_return(@popularity_lookup)
    expect(@popularity_lookup).to receive(:lookup_popularities).with([payload['base_path']]).and_return(payload["base_path"] => popularity)

    presenter = common_fields_presenter(payload)

    assert_equal popularity, presenter.popularity
  end

  it "no_popularity_when_no_value_is_returned_from_lookup" do
    payload = { "base_path" => "/some/path" }

    expect(Indexer::PopularityLookup).to receive(:new).with('govuk_index', SearchConfig.instance).and_return(@popularity_lookup)
    expect(@popularity_lookup).to receive(:lookup_popularities).with([payload['base_path']]).and_return({})

    presenter = common_fields_presenter(payload)

    assert_equal nil, presenter.popularity
  end

  def common_fields_presenter(payload)
    GovukIndex::CommonFieldsPresenter.new(payload)
  end
end
