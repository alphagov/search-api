# Snapshot and Restore Tasks

Rummager defines several rake tasks to assist in

  * restoring the search indexes to an earlier state
  * rebuilding indexes with updated popularity data
  * mirroring the search indexes between environments

This is built on top of elasticsearch's snapshot/restore functionality,
documented at <https://www.elastic.co/guide/en/elasticsearch/reference/1.4/modules-snapshots.html>

## How snapshot/restore works in elasticsearch

The Elasticsearch API allows us to create snapshots of one or more
indexes.

The snapshots live in a `repository`, which maps to some remote data store,
such as a location in the file system, or in our case an AWS S3 bucket.

Each snapshot is incremental, so successive snapshots don't necessarily use
up extra storage, but there will be redundancy in the stored data, due to things
like elasticsearch merging shards over time, or us rebuilding an index entirely.
Because of this, we regularly delete old snapshots.

### Index aliases

Aliases are like symbolic links to one or more indices, and can be changed
atomically.

Rummager uses aliases to avoid downtime when restoring a snapshot or rebuilding
an index.

For example, during a restore operation, we follow the following steps:

1. `mainstream` -> `mainstream-2016-02-25t17:07:13z-8efbb505-759a-4a34-ae0e-85aad065932d`
2. Restore mainstream from a snapshot to a new index, `restored-mainstream-2016-02-25t17:11:04z-6d2a7dc4-a3b7-4572-b388-c59dc2c40be5`
3. Wait for the restore to complete. Searches will continue to use the old
index.
3. Switch the alias: `mainstream` -> `restored-mainstream-2016-02-25t17:11:04z-6d2a7dc4-a3b7-4572-b388-c59dc2c40be5`
4. Searches now use the new index.

## Repository setup

If you have an S3 bucket set up, you can create a snapshot repository yourself
by running:

```
rake rummager:snapshot:create_repository
```

This assumes you have some environment variables available:

- AWS_ACCESS_KEY_ID
- AWS_ACCESS_SECRET_ACCESS_KEY
- AWS_BUCKET_NAME
- AWS_BUCKET_REGION

Default values such as `repository_name` and `snapshot_max_age` are set in: `elasticsearch.yml`.

If you want to create your own repository (e.g. for development), you might
want to create a filesystem backed repository instead. This is documented in
the [elasticsearch documentation for snapshot restore](https://www.elastic.co/guide/en/elasticsearch/reference/1.4/modules-snapshots.html).

You won't be able to use the `rummager:snapshot:list` and `rummager:snapshot:latest`
tasks without an S3 bucket, but the basic snapshot/restore can work with any
repository type.

## Start a snapshot
Normally, snapshots are triggered regularly from a cron job.

You can initiate a snapshot manually by running:

```shell
rake rummager:snapshot:run[repository_name,snapshot_name]
```

Optional parameters: `repository_name`, `snapshot_name`

As above, you will need to ensure that AWS environment variables are set.

If snapshot_name is left out, Rummager generates one based on the current time.

If the repository does not exist, or Elasticsearch is unable to process the
request, the task exits with a non zero code and prints a stack trace.

Otherwise the exit code will be zero.

## Monitoring snapshots
### Check if a snapshot has completed yet
```shell
rake rummager:snapshot:check[repository_name,snapshot_name]
```

Optional parameters: `repository_name`, `snapshot_name`

This returns the status of a snapshot operation, e.g. "SUCCESS".

### Find the last successful snapshot
```shell
# Print the name of the latest snapshot
rake rummager:snapshot:latest[before_time,repository_name]

# Print the last snapshot excluding any after Jan 1st 2016
rake 'rummager:snapshot:latest[2016-01-01 00:00:00]'
```

Optional parameters: `repository_name`, `before_time`

Where `before_time` defaults to the time in which the rake task is run.

If you are providing a custom `before_time`, it should be in a DateTime format.

This is used to monitor the ongoing snapshot process and make sure our
repository is keeping up to date.

### List all snapshots in the S3 bucket

```shell
# Includes in-progress snapshots
rake rummager:snapshot:list[repository_name]
```

Optional parameters: `repository_name`

This command also requires AWS environment variables to be set.

## Restore the latest snapshot
```shell
INDEX_NAMES=all rake rummager:snapshot:restore[snapshot_name, repository_name]
```

Optional parameters: `repository_name`

Prints the names of the indexes that will be created.

Exits with a non-zero code and prints a stack trace if elasticsearch is
unable to handle a request. Only one restore operation can happen at a time.

## Monitor a restore from snapshot
```shell
rake rummager:check_recovery[new_index_name,repository_name]
```

Optional parameters: `repository_name`

Prints "true" or "false", depending on whether the restore is complete.

Where `new_index_name` is the name that was printed by the `rummager:snapshot:restore`
task. If in doubt, the [elasticsearch recovery API](https://www.elastic.co/guide/en/elasticsearch/reference/1.4/indices-recovery.html) can list all restored
indexes.

## Switch an index alias to a restored index

Once an index has been successfully restored from a snapshot, you can switch
over the alias:
```shell
INDEX_NAMES=mainstream rake rummager:switch_to_named_index[new_index_name]
```

## Delete old snapshots from the repository

Delete snapshot older than a specific time:

```shell
rake rummager:clean[snapshot_max_age,repository_name]
```

Optional parameters: `snapshot_max_age`, `repository_name`

Where `snapshot_max_age` defaults to 24 hours.

## Nightly rebuild process

There is a nightly jenkins job to rebuild the search indexes. This is also
responsible for cleaning up out of date snapshots.
