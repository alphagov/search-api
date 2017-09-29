require 'spec_helper'

RSpec.describe 'GovukIndex::SwitchOnFormatsInGovukIndexTest', tags: ['integration'] do
  before do
    insert_document('mainstream_test', title: 'mainstream answer', link: '/mainstream/answer', format: 'answer')
    insert_document('mainstream_test', title: 'mainstream help', link: '/mainstream/help', format: 'help_page')
    commit_index
    insert_document('govuk_test', title: 'govuk answer', link: '/govuk/answer', format: 'answer')
    insert_document('govuk_test', title: 'govuk help', link: '/govuk/help', format: 'help_page')
    commit_index('govuk_test')
  end

  it "defaults_to_excluding_govuk_index_records" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return([])

    get "/search"

    expect(parsed_response['results'].map { |r| r['title'] }.sort).to eq(['mainstream answer', 'mainstream help'])
  end

  it "can_enable_format_to_use_govuk_index" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return(['help_page'])

    get "/search"

    expect(parsed_response['results'].map { |r| r['title'] }.sort).to eq(['govuk help', 'mainstream answer'])
  end

  it "can_enable_multiple_formats_to_use_govuk_index" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return(%w(help_page answer))

    get "/search"

    expect(parsed_response['results'].map { |r| r['title'] }.sort).to eq(['govuk answer', 'govuk help'])
  end
end
