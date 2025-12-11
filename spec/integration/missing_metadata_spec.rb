require "spec_helper"

RSpec.describe "MissingMetadataTest" do
  describe "#retrieve_records_with_missing_value" do
    it "finds missing content_id" do
      commit_document(
        "government_test",
        {
          "link" => "/path/to_page",
        },
      )

      runner = MissingMetadata::Runner.new("content_id", search_config: SearchConfig.default_instance, logger: io)
      results = runner.retrieve_records_with_missing_value

      expect([{ _id: "/path/to_page", index: "government_test" }]).to eq results
    end

    it "ignores external links" do
      commit_document(
        "government_test",
        {
          "link" => "https://www.nhs.uk",
        },
      )

      runner = MissingMetadata::Runner.new("content_id", search_config: SearchConfig.default_instance, logger: io)
      results = runner.retrieve_records_with_missing_value

      expect(results).to be_empty
    end

    it "ignores already set content_id" do
      commit_document(
        "government_test",
        {
          "link" => "/path/to_page",
          "content_id" => "8aea1742-9cc6-4dfb-a63b-12c3e66a601f",
        },
      )

      runner = MissingMetadata::Runner.new("content_id", search_config: SearchConfig.default_instance, logger: io)
      results = runner.retrieve_records_with_missing_value

      expect(results).to be_empty
    end

    it "finds missing document_type" do
      commit_document(
        "government_test",
        {
          "link" => "/path/to_page",
          "content_id" => "8aea1742-9cc6-4dfb-a63b-12c3e66a601f",
        },
      )

      runner = MissingMetadata::Runner.new("content_store_document_type", search_config: SearchConfig.default_instance, logger: io)
      results = runner.retrieve_records_with_missing_value

      expect([{ _id: "/path/to_page", index: "government_test", content_id: "8aea1742-9cc6-4dfb-a63b-12c3e66a601f" }]).to eq results
    end

    it "ignores already set document_type" do
      commit_document(
        "government_test",
        {
          "link" => "/path/to_page",
          "content_id" => "8aea1742-9cc6-4dfb-a63b-12c3e66a601f",
          "content_store_document_type" => "guide",
        },
      )

      runner = MissingMetadata::Runner.new("content_store_document_type", search_config: SearchConfig.default_instance, logger: io)
      results = runner.retrieve_records_with_missing_value

      expect(results).to be_empty
    end
  end

  describe "#update" do
    context "when add metadata returns an error" do
      it "logs a message and skips the result" do
        commit_document(
          "government_test",
          {
            "link" => "/path/to_page",
          },
        )
        allow_any_instance_of(MissingMetadata::Fetcher).to receive(:add_metadata).and_raise(StandardError)

        MissingMetadata::Runner.new("content_store_document_type", search_config: SearchConfig.default_instance, logger: io).update

        expect(io.string).to include("Skipped result //path/to_page: StandardError")
      end
    end

    context "when fetcher adds meta data" do
      before do
        @base_path = "/path/to_page"
        @content_id = "8aea1742-9cc6-4dfb-a63b-12c3e66a601f"
        @publishing_content_item = {
          content_id: @content_id,
          document_type: "edition",
          publishing_app: "publisher",
          rendering_app: "frontend",
        }
        @updated_content_item = {
          "content_id" => @content_id,
          "content_store_document_type" => "edition",
          "publishing_app" => "publisher",
          "rendering_app" => "frontend",
        }
        @get_content_id_url = "#{::GdsApi::TestHelpers::PublishingApi::PUBLISHING_API_ENDPOINT}/lookup-by-base-path"
        @get_content_url = "#{::GdsApi::TestHelpers::PublishingApi::PUBLISHING_API_V2_ENDPOINT}/content/#{@content_id}"

        stub_publishing_api_has_expanded_links({ content_id: @content_id }, with_drafts: false)
      end

      context "when content_id is available" do
        it "gets content from publishing api and updates document" do
          commit_document(
            "government_test",
            {
              "link" => @base_path,
              "content_id" => @content_id,
            },
          )
          stub_publishing_api_has_item(@publishing_content_item)

          MissingMetadata::Runner.new("content_store_document_type", search_config: SearchConfig.default_instance, logger: io).update

          expect(a_request(:get, @get_content_url)).to have_been_made.once
          expect_document_is_in_rummager(@updated_content_item, index: "government_test", id: @base_path)
        end
      end

      context "when fetch content times out" do
        it "sleeps for 1 second and retries, until content is returned" do
          commit_document(
            "government_test",
            {
              "link" => @base_path,
              "content_id" => @content_id,
            },
          )
          allow(Kernel).to receive(:sleep).and_return(true)
          stub_request(:get, @get_content_url).with(query: hash_including({}))
            .to_timeout
            .then
            .to_return(status: 200, body: @publishing_content_item.to_json, headers: {})

          MissingMetadata::Runner.new("content_store_document_type", search_config: SearchConfig.default_instance, logger: io).update

          expect(a_request(:get, @get_content_url)).to have_been_made.twice
          expect(Kernel).to have_received(:sleep).with(1).exactly(1).times
          expect(io.string).to include("Publishing API timed out getting content... retrying")
          expect_document_is_in_rummager(@updated_content_item, index: "government_test", id: @base_path)
        end
      end

      context "when content_id is not available" do
        it "gets content id and content from publishing api and updates document" do
          commit_document(
            "government_test",
            {
              "link" => @base_path,
            },
          )
          stub_publishing_api_has_lookups(@base_path => @content_id)
          stub_publishing_api_has_item(@publishing_content_item)

          MissingMetadata::Runner.new("content_store_document_type", search_config: SearchConfig.default_instance, logger: io).update

          expect(a_request(:post, @get_content_id_url)).to have_been_made.once
          expect(a_request(:get, @get_content_url)).to have_been_made.once
          expect_document_is_in_rummager(@updated_content_item, index: "government_test", id: @base_path)
        end
      end

      context "when fetch content_id times out" do
        it "sleeps for 1 second and retries, until content_id is returned" do
          commit_document(
            "government_test",
            {
              "link" => @base_path,
            },
          )
          allow(Kernel).to receive(:sleep).and_return(true)
          lookup_hash = { @base_path => @content_id }
          stub_request(:post, @get_content_id_url)
                .to_timeout
                .then
                .to_return(body: lookup_hash.to_json)
          stub_publishing_api_has_item(@publishing_content_item)

          MissingMetadata::Runner.new("content_store_document_type", search_config: SearchConfig.default_instance, logger: io).update

          expect(a_request(:post, @get_content_id_url)).to have_been_made.twice
          expect(a_request(:get, @get_content_url)).to have_been_made.once
          expect(Kernel).to have_received(:sleep).with(1).exactly(1).times
          expect(io.string).to include("Publishing API timed out getting content_id... retrying")
          expect_document_is_in_rummager(@updated_content_item, index: "government_test", id: @base_path)
        end
      end
    end
  end

  def io
    @io ||= StringIO.new
  end
end
