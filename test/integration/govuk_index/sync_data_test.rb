require 'integration_test_helper'

class GovukIndex::SyncDataTest < IntegrationTest
  def setup
    super
    GovukIndex::MigratedFormats.stubs(:indexable_formats).returns(['help_page'])
  end

  def test_syncs_records_for_non_indexable_formats
    insert_document('mainstream_test', { link: '/test', popularity: 0.3, format: 'edition' }, id: '/test', type: 'edition')
    commit_index('mainstream_test')

    GovukIndex::SyncUpdater.update(source_index: 'mainstream_test', destination_index: 'govuk_test')

    assert_document_is_in_rummager({ 'link' => '/test' }, type: 'edition', index: 'govuk_test')
  end

  def test_syncs_will_overwrite_existing_data
    insert_document('mainstream_test', { link: '/test', popularity: 0.3, format: 'edition' }, id: '/test', type: 'edition')
    commit_index('mainstream_test')
    insert_document('govuk_test', { link: '/test', popularity: 0.4, format: 'edition' }, id: '/test', type: 'edition')
    commit_index('govuk_test')

    GovukIndex::SyncUpdater.update(source_index: 'mainstream_test', destination_index: 'govuk_test')

    assert_document_is_in_rummager({ 'link' => '/test', 'popularity' => 0.3 }, type: 'edition', index: 'govuk_test')
  end


  def test_will_not_syncs_records_for_indexable_formats
    insert_document('mainstream_test', { link: '/test', popularity: 0.3, format: 'help_page' }, id: '/test', type: 'edition')
    commit_index('mainstream_test')
    insert_document('govuk_test', { link: '/test', popularity: 0.4, format: 'help_page' }, id: '/test', type: 'edition')
    commit_index('govuk_test')

    GovukIndex::SyncUpdater.update(source_index: 'mainstream_test', destination_index: 'govuk_test')

    assert_document_is_in_rummager({ 'link' => '/test', 'popularity' => 0.4 }, type: 'edition', index: 'govuk_test')
  end
end
