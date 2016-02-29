require "test_helper"
require "elasticsearch/snapshot_repository"
require "minitest/mock"


class SnapshotRepositoryTest < MiniTest::Unit::TestCase
  def setup
    @snapshot_repository = Elasticsearch::SnapshotRepository.new(
      base_uri: "localhost:9000/repository/",
      repository_name: "test-repository",
    )
  end

  def test_last_successful_snapshot
    @snapshot_repository.stub :in_progress_snapshots, ["in-progress-1", "in-progress-2"] do
      all_snapshots = ["completed-1", "completed-2", "in-progress-1", "in-progress-2"]
      assert @snapshot_repository.last_successful_snapshot(all_snapshots) == "completed-2"
    end
  end

  def test_select_indices_from_groups
    groups = %w(mainstream government)
    indices = ["mainstream-2016-01-01....", "government-2016-01-01....", "service-manual-2016-01-01..."]
    result = Elasticsearch::SnapshotRepository.select_indices_from_groups(indices, groups)
    assert_equal(
      result,
      { groups[0] => indices[0], groups[1] => indices[1] }
    )
  end
end
