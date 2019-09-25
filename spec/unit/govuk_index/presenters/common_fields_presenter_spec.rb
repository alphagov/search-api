require "spec_helper"

RSpec.describe GovukIndex::CommonFieldsPresenter do
  before do
    @popularity_lookup = double(:popularity_lookup)
    allow(Indexer::PopularityLookup).to receive(:new).and_return(@popularity_lookup)
    allow(@popularity_lookup).to receive(:lookup_popularities).and_return({})

    @directly_mapped_fields = %w(
      content_id
      email_document_supertype
      government_document_supertype
      navigation_document_supertype
      publishing_app
      rendering_app
      search_user_need_document_supertype
      user_journey_document_supertype
    )
  end

  it "directly mapped fields" do
    payload = generate_random_example(
      payload: { expanded_links: {} },
      excluded_fields: ["withdrawn_notice"],
      regenerate_if: ->(example) {
        @directly_mapped_fields.any? { |field| example[field] == "" }
      },
    )

    presenter = common_fields_presenter(payload)

    @directly_mapped_fields.each do |field|
      expect(presenter.public_send(field)).to eq(payload[field])
    end
  end

  it "non directly mapped fields" do
    defined_fields = {
      base_path: "/some/path",
      expanded_links: {},
    }

    payload = generate_random_example(
      payload: defined_fields,
      excluded_fields: ["withdrawn_notice"],
    )

    presenter = common_fields_presenter(payload)

    expect(presenter.format).to eq(payload["document_type"])
    expect(presenter.is_withdrawn).to eq(false)
    expect(presenter.link).to eq(payload["base_path"])
  end

  it "uses the URL as the link for external content" do
    payload = {
      "document_type" => "external_content",
      "details" => {
        "url" => "some_url",
      },
    }

    presenter = common_fields_presenter(payload)

    expect(presenter.link).to eq("some_url")
  end

  it "adjusts the title and description for the Brexit topic page" do
    payload = {
      "content_id" => "d6c2de5d-ef90-45d1-82d4-5f2438369eea",
      "title" => "some title",
      "description" => "some description",
    }

    presenter = common_fields_presenter(payload)

    expect(presenter.title).to eq("Get ready for Brexit")
    expect(presenter.description).to eq("The UK is leaving the EU, find out how you should get ready for Brexit.")
  end

  it "withdrawn when withdrawn notice present" do
    payload = {
      "base_path" => "/some/path",
      "withdrawn_notice" => {
        "explanation" => "<div class=\"govspeak\"><p>test 2</p>\n</div>",
        "withdrawn_at" => "2017-08-03T14:02:18Z",
      },
    }

    presenter = common_fields_presenter(payload)

    expect(presenter.is_withdrawn).to eq(true)
  end

  it "popularity when value is returned from lookup" do
    payload = { "base_path" => "/some/path" }

    popularity = 0.0125356
    popularity_rank = 0.001

    # rubocop:disable RSpec/MessageSpies
    expect(Indexer::PopularityLookup).to receive(:new).with("govuk_index", instance_of(SearchConfig)).and_return(@popularity_lookup)
    expect(@popularity_lookup).to receive(:lookup_popularities).with([payload["base_path"]]).and_return(
      payload["base_path"] => {
        popularity_score: popularity,
        popularity_rank: popularity_rank,
      }
    )
    # rubocop:enable RSpec/MessageSpies

    presenter = common_fields_presenter(payload)

    expect(popularity).to eq(presenter.popularity)
    expect(popularity_rank).to eq(presenter.popularity_b)
  end

  it "no popularity when no value is returned from lookup" do
    payload = { "base_path" => "/some/path" }

    # rubocop:disable RSpec/MessageSpies
    expect(Indexer::PopularityLookup).to receive(:new).with("govuk_index", instance_of(SearchConfig)).and_return(@popularity_lookup)
    expect(@popularity_lookup).to receive(:lookup_popularities).with([payload["base_path"]]).and_return({})
    # rubocop:enable RSpec/MessageSpies

    presenter = common_fields_presenter(payload)

    expect(presenter.popularity).to be_nil
    expect(presenter.popularity_b).to be_nil
  end

  def common_fields_presenter(payload)
    described_class.new(payload)
  end
end
