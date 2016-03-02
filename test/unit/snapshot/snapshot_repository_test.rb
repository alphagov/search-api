require "test_helper"
require "snapshot/snapshot_repository"

class SnapshotRepositoryTest < MiniTest::Unit::TestCase
  def setup
    @snapshot_repository = Snapshot::SnapshotRepository.new(
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
    result = @snapshot_repository.send(:select_indices_from_groups, indices, groups)
    assert_equal(
      result,
      [indices[0], indices[1]]
    )
  end
end

class SnapshotRestorerTest < MiniTest::Unit::TestCase
  def create_restorer(indices)
    Timecop.freeze(DateTime.new(2016, 4, 1)) do
      SecureRandom.stub(:uuid, "123abc") do
        @restorer = Snapshot::Restorer.new(
          client: Minitest::Mock.new,
          repository_name: "test-repository",
          snapshot_name: "test-snapshot",
          snapshot_indices: indices
        )
      end
    end
  end

  def test_rename_pattern
    restorer = create_restorer(["mainstream-2016-03-04t12:20:43z-bef6d9dd-0b71-4c93-a613-757352fd3826"])
    result = restorer.restored_index_names
    assert_equal(
      result,
      ["restored-mainstream-2016-04-01t00:00:00z-123abc"]
    )
  end

  def test_restore_a_restore
    restorer = create_restorer(["restored-mainstream-2016-03-04t12:20:43z-bef6d9dd-0b71-4c93-a613-757352fd3826"])
    result = restorer.restored_index_names
    assert_equal(
      result,
      ["restored-mainstream-2016-04-01t00:00:00z-123abc"]
    )
  end

  def test_restore_hyphenated_index
    restorer = create_restorer(["service-manual-2016-03-04t12:20:43z-bef6d9dd-0b71-4c93-a613-757352fd3826"])
    result = restorer.restored_index_names
    assert_equal(
      result,
      ["restored-service-manual-2016-04-01t00:00:00z-123abc"]
    )
  end
end
