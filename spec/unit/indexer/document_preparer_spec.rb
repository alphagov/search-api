require "spec_helper"

RSpec.describe Indexer::DocumentPreparer do
  let(:content_id) { "DOCUMENT_CONTENT_ID" }
  subject { described_class.new("fake_client", "fake_index") }

  before :each do
    stub_publishing_api_has_lookups({ "/some-link" => content_id })
  end
  describe "#prepared" do
    let(:doc_hash) { { "link" => "/some-link" } }
    before do
      stub_publishing_api_has_expanded_links({ content_id: }, with_drafts: false)
    end
    describe "prepare_popularity_field" do
      it "populates popularities" do
        popularities = { "/some-link" => { popularity_score: 0.5, popularity_rank: 0.01, view_count: 100 } }

        updated_hash = subject.prepared(doc_hash, popularities, true)
        expect(updated_hash).to include("popularity" => 0.5, "popularity_b" => 0.01, "view_count" => 100)
      end

      it "sets the popularity scores to 0 if not present" do
        updated_hash = subject.prepared(doc_hash, {}, true)

        expect(updated_hash).to include("popularity" => 0.0, "popularity_b" => 0.0, "view_count" => 0)
      end
    end

    describe "prepare_format_field" do
      context "when format is nil" do
        let(:doc_hash) { { "document_type" => "guide", "format" => nil } }

        it "sets format to the document_type" do
          expect(subject.prepared(doc_hash, {}, true)).to include("format" => "guide")
        end
      end

      context "when format is present" do
        let(:doc_hash) { { "document_type" => "guide", "format" => "manual" } }

        it "leaves the format unchanged" do
          expect(subject.prepared(doc_hash, {}, true)).to include("format" => "manual")
        end
      end
    end

    describe "prepare_tags_field" do
      let(:doc_hash) { { "content_id" => content_id, "link" => "/some-link" } }

      it "adds tags from the publishing api" do
        stub_publishing_api_has_expanded_links(
          {
            content_id:,
            expanded_links: {
              mainstream_browse_pages: [
                {
                  title: "Bla",
                  base_path: "/browse/my-browse",
                },
              ],
            },
          },
          with_drafts: false,
        )
        updated_doc_hash = subject.prepared(doc_hash, {}, true)
        expect(updated_doc_hash).to include("mainstream_browse_pages" => %w[my-browse])
      end

      describe "The expanded links throws an exception" do
        before do
          stub_const("Indexer::LinksLookup::MAX_ATTEMPTS", 1)

          expanded_links_times_out(content_id)
        end
        it "raises an exception" do
          expect { subject.prepared(doc_hash, {}, true) }.to raise_error(Indexer::PublishingApiError)
        end
        it "does not raise an error if LOG_FAILED_LINKS_LOOKUP_AND_CONTINUE is set" do
          ClimateControl.modify("LOG_FAILED_LINKS_LOOKUP_AND_CONTINUE" => "1") do
            expect { supress_stdout { subject.prepared(doc_hash, {}, true) } }.to_not raise_error
            expect { subject.prepared(doc_hash, {}, true) }.to output(a_string_including("Unable to lookup links for link: /some-link")).to_stdout
          end
        end
      end
    end

    describe "prepare_attachments_field" do
      let(:doc_hash) do
        { "document_type" => "guide",
          "format" => nil,
          "link" => "https://external",
          "attachments" => [{ "title" => "a title",
                              "unique_reference" => "1234",
                              "attachment_type" => "html",
                              "url" => "/some-link" }] }
      end

      it "adds attachments" do
        stub_publishing_api_has_item({ content_id:, "details" => { "body" => "this is content" }, publication_state: "published" })
        updated_doc_hash = subject.prepared(doc_hash, {}, true)
        expect(updated_doc_hash).to include("attachments" => [{ "content" => "this is content",
                                                                "title" => "a title",
                                                                "unique_reference" => "1234" }])
      end

      it "raises an exception" do
        stub_const("Indexer::AttachmentsLookup::MAX_ATTEMPTS", 1)
        get_content_times_out(content_id)
        expect { subject.prepared(doc_hash, {}, true) }.to raise_error(Indexer::PublishingApiError)
      end

      it "does not raise an error if LOG_FAILED_ATTACHMENTS_LOOKUP_AND_CONTINUE is set" do
        stub_const("Indexer::LinksLookup::MAX_ATTEMPTS", 1)
        get_content_times_out(content_id)
        ClimateControl.modify("LOG_FAILED_ATTACHMENTS_LOOKUP_AND_CONTINUE" => "1") do
          expect { supress_stdout { subject.prepared(doc_hash.deep_dup, {}, true) } }.to_not raise_error
          expect { subject.prepared(doc_hash.deep_dup, {}, true) }.to output(a_string_including("Unable to lookup attachments for link: https://external")).to_stdout
        end
      end
    end

    describe "prepare_parts_field" do
      let(:doc_hash) do
        { "document_type" => "guide",
          "format" => nil,
          "link" => "https://external",
          "attachments" => [{ "title" => "a title",
                              "unique_reference" => "1234",
                              "attachment_type" => "html",
                              "url" => "/some-link" }] }
      end
      it "adds parts" do
        stub_publishing_api_has_item({ content_id:, "details" => { "body" => "this is content" }, publication_state: "published" })
        updated_doc_hash = subject.prepared(doc_hash, {}, true)
        expect(updated_doc_hash).to include("parts" => [{ "slug" => "some-link",
                                                          "link" => "/some-link",
                                                          "title" => "a title",
                                                          "body" => "this is content" }])
      end
    end

    describe "add_self_to_organisations_links" do
      it "adds self to organisations links" do
        doc_hash = {
          "slug" => "org3",
          "format" => "organisation",
          "organisations" => %w[org1 org2],
        }
        updated_doc_hash = subject.prepared(doc_hash, {}, true)
        expect(updated_doc_hash["organisations"]).to eq(%w[org1 org2 org3])
      end
      it "does not add self to non-organisations links" do
        doc_hash = {
          "slug" => "org3",
          "format" => "non-organisation",
          "organisations" => %w[org1 org2],
        }
        updated_doc_hash = subject.prepared(doc_hash, {}, true)
        expect(updated_doc_hash["organisations"]).to eq(%w[org1 org2])
      end
      it "handles non-existent slugs" do
        doc_hash = {
          "format" => "organisation",
          "organisations" => %w[org1 org2],
        }
        updated_doc_hash = subject.prepared(doc_hash, {}, true)
        expect(updated_doc_hash["organisations"]).to eq(%w[org1 org2])
      end
      it "does not add organisation twice" do
        doc_hash = {
          "slug" => "org3",
          "format" => "organisation",
          "organisations" => %w[org1 org2 org3],
        }
        updated_doc_hash = subject.prepared(doc_hash, {}, true)
        expect(updated_doc_hash["organisations"]).to eq(%w[org1 org2 org3])
      end
      it "adds itself even if there are no organisations" do
        doc_hash = {
          "slug" => "org3",
          "format" => "organisation",
        }
        updated_doc_hash = subject.prepared(doc_hash, {}, true)
        expect(updated_doc_hash["organisations"]).to eq(%w[org3])
        expect(updated_doc_hash["organisations"]).to eq(%w[org3])
      end
    end

    describe "prepare_document_supertypes" do
      it "prepare_document_supertypes" do
        doc_hash = {
          "link" => "/some-link",
          "content_store_document_type" => "detailed_guide",
        }
        updated_doc_hash = subject.prepared(
          doc_hash,
          {},
          true,
        )

        expect(updated_doc_hash["content_purpose_supergroup"]).to eq("guidance_and_regulation")
        expect(updated_doc_hash["content_purpose_subgroup"]).to eq("guidance")
      end
    end

    describe "prepare_if_best_bet" do
      let(:client) { instance_double(Elasticsearch::Transport::Client) }
      let(:indices) { instance_double(Elasticsearch::API::Indices::IndicesClient) }
      before do
        allow(client).to receive(:indices).and_return(indices)
      end

      subject { described_class.new(client, "govuk") }

      it "adds a best bet" do
        allow(indices).to receive(:analyze).with(index: "govuk",
                                                 body: {
                                                   text: "this will be stemmed",
                                                   analyzer: "best_bet_stemmed_match",
                                                 }).and_return("tokens" => [{ "token" => "this" },
                                                                            { "token" => "will" },
                                                                            { "token" => "be" },
                                                                            { "token" => "stem" }])

        doc_hash = {
          "document_type" => "best_bet",
          "stemmed_query" => "this will be stemmed",
          "link" => "https://external",
        }
        updated_doc_hash = subject.prepared(
          doc_hash,
          {},
          true,
        )
        expect(updated_doc_hash).to have_key("stemmed_query_as_term")
        expect(updated_doc_hash["stemmed_query_as_term"].strip).to eq("this will be stem")
      end
      it "ignores non best bets" do
        doc_hash = {
          "document_type" => "not_best_bet",
          "stemmed_query" => "this will be ignored",
          "link" => "https://external",
        }
        updated_doc_hash = subject.prepared(doc_hash,
                                            {},
                                            true)
        expect(updated_doc_hash).not_to have_key("stemmed_query_as_term")
      end
      it "ignores if no stemmed query is set" do
        doc_hash = {
          "document_type" => "best_bet",
          "link" => "https://external",
        }
        updated_doc_hash = subject.prepared(doc_hash,
                                            {},
                                            true)
        expect(updated_doc_hash).not_to have_key("stemmed_query_as_term")
      end
      it "handles a BadRequest error" do
        allow(indices).to receive(:analyze).and_raise(Elasticsearch::Transport::Transport::Errors::BadRequest)

        doc_hash = {
          "document_type" => "best_bet",
          "stemmed_query" => "this will be stemmed",
          "link" => "https://external",
        }
        updated_doc_hash = subject.prepared(doc_hash,
                                            {},
                                            true)
        expect(updated_doc_hash["stemmed_query_as_term"].strip).to eq("")
      end
    end

    it "removes _type and _id from the document hash" do
      doc_hash = {
        "_type" => "edition",
        "_id" => "1234",
        "document_type" => "best_bet",
        "link" => "https://external",
      }
      updated_doc_hash = subject.prepared(doc_hash,
                                          {},
                                          true)
      expect(updated_doc_hash).not_to have_key("_type")
      expect(updated_doc_hash).not_to have_key("_id")
    end
  end

  def expanded_links_times_out(content_id)
    url = "#{::GdsApi::TestHelpers::PublishingApi::PUBLISHING_API_V2_ENDPOINT}/expanded-links/#{content_id}"
    stub_request(:get, url).with(query: hash_including({})).to_timeout
  end

  def get_content_times_out(content_id)
    url = "#{::GdsApi::TestHelpers::PublishingApi::PUBLISHING_API_V2_ENDPOINT}/content/#{content_id}"
    stub_request(:get, url).with(query: hash_including({})).to_timeout
  end

  def supress_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end
end
