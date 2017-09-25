require 'spec_helper'

RSpec.describe 'GovukIndex::UpdatingPopularityDataTest', tags: ['integration'] do
  before do
    GovukIndex::MigratedFormats.stubs(:indexable_formats).returns(['help_page'])
  end

  it "updates_the_popularity_when_it_exists" do
    id = insert_document('govuk_test', { popularity: 0.222, format: 'help_page' }, type: 'edition')
    commit_index('govuk_test')

    document_count = 4
    document_rank = 2
    insert_document('page-traffic_test', { rank_14: document_rank, path_components: [id, '/test'] }, id: id, type: 'page-traffic')
    setup_page_traffic_data(document_count: document_count)

    popularity = 1.0 / ([document_rank, document_count].min + SearchConfig.instance.popularity_rank_offset)

    GovukIndex::PopularityUpdater.update('govuk_test')

    assert_document_is_in_rummager({ 'link' => id, 'popularity' => popularity }, type: 'edition', index: 'govuk_test')
  end

  it "set_the_popularity_to_the_lowest_popularity_when_it_doesnt_exist" do
    id = insert_document('govuk_test', { popularity: 0.222, format: 'help_page' }, type: 'edition')
    commit_index('govuk_test')

    document_count = 4
    setup_page_traffic_data(document_count: document_count)

    popularity = 1.0 / (document_count + SearchConfig.instance.popularity_rank_offset)

    GovukIndex::PopularityUpdater.update('govuk_test')

    assert_document_is_in_rummager({ 'link' => id, 'popularity' => popularity }, type: 'edition', index: 'govuk_test')
  end

  it "ignores_popularity_update_if_version_has_moved_on" do
    id = insert_document('govuk_test', { popularity: 0.222, format: 'help_page' }, type: 'edition', version: 2)
    commit_index('govuk_test')

    document_count = 4
    setup_page_traffic_data(document_count: document_count)

    ScrollEnumerator.stubs(:new).returns([
      {
        identifier: { '_id' => id, '_type' => 'edition', '_version' => 1 },
        document: { link: id, popularity: 0.222 },
      }
    ])

    GovukIndex::PopularityUpdater.update('govuk_test')

    assert_document_is_in_rummager({ 'link' => id, 'popularity' => 0.222 }, type: 'edition', index: 'govuk_test')
  end

  it "copies_version_information" do
    id = insert_document('govuk_test', { popularity: 0.222, format: 'help_page' }, type: 'edition', version: 3)
    commit_index('govuk_test')
    GovukIndex::PopularityUpdater.update('govuk_test')

    document = fetch_document_from_rummager(id: id, index: 'govuk_test')
    assert_equal 3, document['_version']
  end

  it "skips_non_indexable_formats" do
    id = insert_document('govuk_test', { popularity: 0.222, format: 'edition' }, type: 'edition', version: 3)
    commit_index('govuk_test')
    GovukIndex::PopularityUpdater.update('govuk_test')

    document = fetch_document_from_rummager(id: id, index: 'govuk_test')
    assert_equal 0.222, document['_source']['popularity']
  end

  it "does_not_skips_non_indexable_formats_if_process_all_flag_is_set" do
    id = insert_document('govuk_test', { popularity: 0.222, format: 'edition' }, type: 'edition', version: 3)
    commit_index('govuk_test')

    document_count = 4
    setup_page_traffic_data(document_count: document_count)

    GovukIndex::PopularityUpdater.update('govuk_test', process_all: true)
    popularity = 1.0 / (document_count + SearchConfig.instance.popularity_rank_offset)

    document = fetch_document_from_rummager(id: id, index: 'govuk_test')
    assert_equal popularity, document['_source']['popularity']
  end
end
