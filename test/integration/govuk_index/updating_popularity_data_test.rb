require 'integration_test_helper'

class GovukIndex::UpdatingPopularityDataTest < IntegrationTest
  def setup
    super
    GovukIndex::MigratedFormats.stubs(:indexable_formats).returns(['help_page'])
  end

  def test_updates_the_popularity_when_it_exists
    insert_document('govuk_test', { link: '/test', popularity: 0.3, format: 'help_page' }, id: '/test', type: 'edition')
    commit_index('govuk_test')

    document_count = 4
    document_rank = 2
    insert_document('page-traffic_test', { rank_14: document_rank, path_components: ['/test'] }, id: '/test', type: 'page-traffic')
    setup_page_traffic_data(document_count: document_count)

    popularity = 1.0 / ([document_rank, document_count].min + SearchConfig.instance.popularity_rank_offset)

    GovukIndex::PopularityUpdater.update('govuk_test')

    assert_document_is_in_rummager({ 'link' => '/test', 'popularity' => popularity }, type: 'edition', index: 'govuk_test')
  end

  def test_set_the_popularity_to_the_lowest_popularity_when_it_doesnt_exist
    insert_document('govuk_test', { link: '/test', popularity: 0.3, format: 'help_page' }, id: '/test', type: 'edition')
    commit_index('govuk_test')

    document_count = 4
    setup_page_traffic_data(document_count: document_count)

    popularity = 1.0 / (document_count + SearchConfig.instance.popularity_rank_offset)

    GovukIndex::PopularityUpdater.update('govuk_test')

    assert_document_is_in_rummager({ 'link' => '/test', 'popularity' => popularity }, type: 'edition', index: 'govuk_test')
  end

  def test_ignores_popularity_update_if_version_has_moved_on
    insert_document('govuk_test', { link: '/test', popularity: 0.3, format: 'help_page' }, id: '/test', type: 'edition', version: 2)
    commit_index('govuk_test')

    document_count = 4
    setup_page_traffic_data(document_count: document_count)

    ScrollEnumerator.stubs(:new).returns([
      {
        identifier: { '_id' => '/test', '_type' => 'edition', '_version' => 1 },
        document: { link: '/test', popularity: 0.3 },
      }
    ])

    GovukIndex::PopularityUpdater.update('govuk_test')

    assert_document_is_in_rummager({ 'link' => '/test', 'popularity' => 0.3 }, type: 'edition', index: 'govuk_test')
  end

  def test_copies_version_information
    insert_document('govuk_test', { link: '/test', popularity: 0.3, format: 'help_page' }, id: '/test', type: 'edition', version: 3)
    commit_index('govuk_test')
    GovukIndex::PopularityUpdater.update('govuk_test')

    document = fetch_document_from_rummager(id: '/test', index: 'govuk_test')
    assert_equal 3, document['_version']
  end

  def test_skips_non_indexable_formats
    insert_document('govuk_test', { link: '/test', popularity: 0.3, format: 'edition' }, id: '/test', type: 'edition', version: 3)
    commit_index('govuk_test')
    GovukIndex::PopularityUpdater.update('govuk_test')

    document = fetch_document_from_rummager(id: '/test', index: 'govuk_test')
    assert_equal 0.3, document['_source']['popularity']
  end
end
