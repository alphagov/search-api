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

    assert_equal(['mainstream answer', 'mainstream help'], parsed_response['results'].map { |r| r['title'] }.sort)
  end

  it "can_enable_format_to_use_govuk_index" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return(['help_page'])

    get "/search"

    assert_equal(['govuk help', 'mainstream answer'], parsed_response['results'].map { |r| r['title'] }.sort)
  end

  it "can_enable_multiple_formats_to_use_govuk_index" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return(%w(help_page answer))

    get "/search"

    assert_equal(['govuk answer', 'govuk help'], parsed_response['results'].map { |r| r['title'] }.sort)
  end
end
