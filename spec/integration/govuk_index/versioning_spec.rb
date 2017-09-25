require 'govuk_schemas'
require 'spec_helper'
require 'govuk_index/publishing_event_processor'

RSpec.describe 'GovukIndex::VersioningTest', tags: ['integration'] do
  before do
    @processor = GovukIndex::PublishingEventProcessor.new
  end

  it "should_successfully_index_increasing_version_numbers" do
    GovukIndex::MigratedFormats.stubs(:indexable?).returns(true)

    version1 = generate_random_example(
      payload: { payload_version: 123 },
      regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" },
    )

    base_path = version1["base_path"]
    process_message(version1)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 123, document["_version"]

    version2 = version1.merge(title: "new title", payload_version: 124)
    process_message(version2)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 124, document["_version"]
    assert_equal "new title", document["_source"]["title"]
  end

  it "should_discard_message_with_same_version_as_existing_document" do
    GovukIndex::MigratedFormats.stubs(:indexable?).returns(true)
    version1 = generate_random_example(
      payload: { payload_version: 123 },
      regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" },
    )

    base_path = version1["base_path"]
    process_message(version1)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 123, document["_version"]

    version2 = version1.merge(title: "new title", payload_version: 123)
    process_message(version2)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 123, document["_version"]
    assert_equal version1["title"], document["_source"]["title"]
  end

  it "should_discard_message_with_earlier_version_than_existing_document" do
    GovukIndex::MigratedFormats.stubs(:indexable?).returns(true)

    version1 = generate_random_example(
      payload: { payload_version: 123 },
      regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" }
    )

    base_path = version1["base_path"]
    process_message(version1)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 123, document["_version"]

    version2 = version1.merge(title: "new title", payload_version: 122)
    process_message(version2)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 123, document["_version"]
    assert_equal version1["title"], document["_source"]["title"]
  end

  it "should_delete_and_recreate_document_when_unpublished_and_republished" do
    GovukIndex::MigratedFormats.stubs(:indexable?).returns(true)
    version1 = generate_random_example(
      payload: { payload_version: 1 },
      excluded_fields: ["withdrawn_notice"],
      regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" },
    )

    base_path = version1["base_path"]
    process_message(version1)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 1, document["_version"]

    version2 = generate_random_example(
      schema: 'gone',
      payload: {
        base_path: base_path,
        payload_version: 2
      },
      excluded_fields: ["withdrawn_notice"],
      regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" },
    )
    process_message(version2, unpublishing: true)

    assert_raises(Elasticsearch::Transport::Transport::Errors::NotFound) do
      fetch_document_from_rummager(id: base_path, index: 'govuk_test')
    end

    version3 = version1.merge(payload_version: 3)
    process_message(version3)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 3, document["_version"]
  end

  it "should_discard_unpublishing_message_with_earlier_version" do
    GovukIndex::MigratedFormats.stubs(:indexable?).returns(true)
    version1 = generate_random_example(
      payload: { payload_version: 2 },
      regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" },
    )

    base_path = version1["base_path"]
    process_message(version1)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 2, document["_version"]

    version2 = generate_random_example(
      schema: 'gone',
      payload: {
        base_path: base_path,
        payload_version: 1
      },
      excluded_fields: ["withdrawn_notice"],
      regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" },
    )
    process_message(version2, unpublishing: true)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 2, document["_version"]
  end

  it "should_ignore_event_for_non_indexable_formats" do
    GovukIndex::MigratedFormats.stubs(:indexable?).returns(true)

    version1 = generate_random_example(
      payload: { payload_version: 123 },
      regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" },
    )

    base_path = version1["base_path"]
    process_message(version1)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")

    assert_equal 123, document["_version"]

    GovukIndex::MigratedFormats.stubs(:indexable?).returns(false)

    version2 = version1.merge(title: "new title", payload_version: 124)
    process_message(version2)

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 123, document["_version"]
    assert_equal version1["title"], document["_source"]["title"]
  end

  def process_message(example_document, unpublishing: false)
    @processor.process(stub_message_payload(example_document, unpublishing: unpublishing))
  end
end
