require 'spec_helper'

RSpec.describe DuplicateLinksFinder do
  subject { described_class.new(indices: %w(government_test govuk_test)) }

  it "does not incorrectly report dupliciates" do
    create_document_with(link: "/document-1")
    create_document_with(link: "/document-2")

    expect(subject.find_exact_duplicates).to eq([])
  end

  it "detects duplicates across indices" do
    create_document_with(index: "government_test")
    create_document_with(index: "govuk_test", format: "help_page")

    expect(subject.find_exact_duplicates).to eq(["/an-example-page"])
  end

  it "does not detect duplicates in ignored indices" do
    create_document_with(index: "government_test")
    create_document_with(index: "govuk_test", format: "help_page")

    finder = described_class.new(indices: %w(govuk_test))
    expect(finder.find_exact_duplicates).to eq([])
    expect(subject.find_exact_duplicates).to eq(["/an-example-page"])
  end

  it "does not incorrect detect duplicates in migrated data" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return('edition' => :all)
    create_document_with(index: "government_test", format: "edition")
    create_document_with(index: "govuk_test", format: "edition")

    expect(subject.find_exact_duplicates).to eq([])
  end

  it "can detect duplicates in govuk migrated data" do
    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return('help_page' => :all)
    create_document_with(index: "government_test", format: "edition")
    create_document_with(index: "govuk_test", format: "help_page")

    expect(subject.find_exact_duplicates).to eq(["/an-example-page"])
  end

  def create_document_with(type: "edition", index: "government_test", link: "/an-example-page", format: "edition")
    commit_document(
      index,
      {
        "content_id" => "3c824d6b-d982-4426-9a7d-43f2b865e77c",
        "link" => link,
        "format" => format
      },
      type: type,
    )
  end
end
