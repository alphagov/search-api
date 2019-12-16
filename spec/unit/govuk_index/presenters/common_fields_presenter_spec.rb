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
      excluded_fields: %w[withdrawn_notice],
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
      excluded_fields: %w[withdrawn_notice],
    )

    presenter = common_fields_presenter(payload)

    expect(presenter.format).to eq(payload["document_type"])
    expect(presenter.withdrawn?).to eq(false)
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

    expect(presenter.title).to eq("Brexit")
    expect(presenter.description).to eq("Brexit information and guidance on how to prepare for a no deal Brexit.")
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

    expect(presenter.withdrawn?).to eq(true)
  end

  it "popularity when value is returned from lookup" do
    payload = { "base_path" => "/some/path" }

    popularity = 0.0125356
    popularity_rank = 0.001
    expect(Indexer::PopularityLookup).to receive(:new).with("govuk_index", instance_of(SearchConfig)).and_return(@popularity_lookup)
    expect(@popularity_lookup).to receive(:lookup_popularities).with([payload["base_path"]]).and_return(
      payload["base_path"] => {
        popularity_score: popularity,
        popularity_rank: popularity_rank,
      },
    )


    presenter = common_fields_presenter(payload)

    expect(popularity).to eq(presenter.popularity)
    expect(popularity_rank).to eq(presenter.popularity_b)
  end

  it "no popularity when no value is returned from lookup" do
    payload = { "base_path" => "/some/path" }
    expect(Indexer::PopularityLookup).to receive(:new).with("govuk_index", instance_of(SearchConfig)).and_return(@popularity_lookup)
    expect(@popularity_lookup).to receive(:lookup_popularities).with([payload["base_path"]]).and_return({})


    presenter = common_fields_presenter(payload)

    expect(presenter.popularity).to be_nil
    expect(presenter.popularity_b).to be_nil
  end

  it "assigns political status when document is political" do
    payload = generate_random_example(
      schema: "news_article",
      payload: {
        document_type: "news_story",
      },
      details: {
        political: true,
      },
    )

    presenter = common_fields_presenter(payload)

    expect(presenter.political?).to be true
  end

  it "does not assign political status when document is not political" do
    payload = generate_random_example(
      schema: "news_article",
      payload: {
        document_type: "news_story",
      },
      details: {
        political: false,
      },
    )

    presenter = common_fields_presenter(payload)

    expect(presenter.political?).to be false
  end

  it "set the government name when government is present in linls" do
    payload = generate_random_example(
      schema: "news_article",
      payload: {
        document_type: "news_story",
        expanded_links: {
          "government" => [
            {
              "content_id" => "aa4d1950-8645-43d0-8071-214c70aa1441",
              "title" => "Fictitious government name",
              "locale" => "en",
              "base_path" => "/fictitious-government",
            },
          ],
        },
      },
    )

    presenter = common_fields_presenter(payload)

    expect(presenter.government_name).to eq("Fictitious government name")
  end

  it "sets historic when document is political and government is past" do
    payload = generate_random_example(
      schema: "news_article",
      payload: {
        document_type: "news_story",
        expanded_links: {
          "government" => [
            {
              "content_id" => "aa4d1950-8645-43d0-8071-214c70aa1441",
              "title" => "Fictitious government name",
              "locale" => "en",
              "base_path" => "/fictitious-government",
              "details" => {
                "current" => false,
              },
            },
          ],
        },
      },
      details: {
        political: true,
      },
    )

    presenter = common_fields_presenter(payload)

    expect(presenter.historic?).to be true
  end

  it "does not set historic when document is not political but government is past" do
    payload = generate_random_example(
      schema: "news_article",
      payload: {
        document_type: "news_story",
        expanded_links: {
          "government" => [
            {
              "content_id" => "aa4d1950-8645-43d0-8071-214c70aa1441",
              "title" => "Fictitious government name",
              "locale" => "en",
              "base_path" => "/fictitious-government",
              "details" => {
                "current" => false,
              },
            },
          ],
        },
      },
      details: {
        political: false,
      },
    )

    presenter = common_fields_presenter(payload)

    expect(presenter.historic?).to be false
  end

  it "does not set historic when document is political and government is current" do
    payload = generate_random_example(
      schema: "news_article",
      payload: {
        document_type: "news_story",
        expanded_links: {
          "government" => [
            {
              "content_id" => "aa4d1950-8645-43d0-8071-214c70aa1441",
              "title" => "Fictitious government name",
              "locale" => "en",
              "base_path" => "/fictitious-government",
              "details" => {
                "current" => true,
              },
            },
          ],
        },
      },
      details: {
        political: true,
      },
    )

    presenter = common_fields_presenter(payload)

    expect(presenter.historic?).to be false
  end

  def common_fields_presenter(payload)
    described_class.new(payload)
  end
end
