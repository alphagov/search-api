# Snapshot and Restore Tasks

Rummager defines several rake tasks to assist in

  * restoring the search indexes to an earlier state
  * rebuilding indexes with updated popularity data
  * mirroring the search indexes between environments

This is built on top of elasticsearch's snapshot/restore functionality,
documented at <https://www.elastic.co/guide/en/elasticsearch/reference/1.4/modules-snapshots.html>

You can use these snapshots to set up a local copy of rummager with production
data.

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

> If you wish to make an apple pie from scratch, you must first invent the universe.
>
> -- Carl Sagan

If you have an S3 bucket set up, you can create a snapshot repository yourself
by running:

```
rake rummager:snapshot:create_repository[repository_name]
```

This assumes you have some environment variables available:

- AWS_ACCESS_KEY_ID
- AWS_ACCESS_SECRET_ACCESS_KEY

The name of the bucket to be used is configured in `elasticsearch.yml`.

If you want to create your own repository (e.g. for development), you might
want to create a filesystem backed repository instead. This is documented in
the [elasticsearch documentation for snapshot restore](https://www.elastic.co/guide/en/elasticsearch/reference/1.4/modules-snapshots.html).

You won't be able to use the `rummager:snapshot:list` and `rummager:snapshot:latest`
tasks without an S3 bucket, but the basic snapshot/restore can work with any
repository type.

## Start a snapshot
You can initiate a snapshot by running:

```shell
rake rummager:snapshot:run[repository_name,snapshot_name]
```

If the repository does not exist, or elasticsearch is unable to process the
request, the task exits with a non zero code and prints a stack trace.

Otherwise, it will print an API response. TODO: fix this


## Monitoring snapshots
### Check if a snapshot has completed yet
```shell
rake rummager:snapshot:check[repository_name,snapshot_name]
```
This returns the status of a snapshot operation, e.g. "SUCCESS".

### Find the last successful snapshot
```shell
# Print the name of the latest snapshot
rake rummager:snapshot:latest[repository_name]

# Print the last snapshot excluding any after Jan 1st 2016
rake 'rummager:snapshot:latest[repository_name, 2016-01-01 00:00:00]
```

### List all snapshots in the S3 bucket
```shell
# Includes in-progress snapshots
rake rummager:snapshot:list[repository]
```

## Restore the latest snapshot
```shell
INDEX_NAMES=all rake rummager:snapshot:restore[repository_name,snapshot_name]
```
Prints the names of the indexes that will be created.

Exits with a non-zero code and prints a stack trace if elasticsearch is
unable to handle a request. Only one restore operation should happen at a time.

## Monitor a restore from snapshot
```shell
rake rummager:check_recovery[index_name]
```
Prints "true" or "false". TODO: make this better.

## Switch an index alias to a restored index

Once an index has been successfully restored from a snapshot, you can switch
over the alias:
```shell
INDEX_NAMES=mainstream rake rummager:switch_to_named_index[new_index_name]
```

## Nightly rebuild process

There is a nightly jenkins job to rebuild the search indexes. This is also
responsible for cleaning up out of date snapshots.

## FAQ
### Open questions
Key rotation - when we rotate keys we need to ensure the create repository step is rerun.

Can we add a repository in read-only mode to another env based on the live bucket?

If not, how does a member of the public use the bucket?
