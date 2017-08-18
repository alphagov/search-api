# Decision record: perform popularity updating without using an index lock

## Context

The current nightly job works by:
 
1. locking the current index
1. queuing all records from the index
1. starting threaded works to insert the records into the new index with the updated popularity
1. waiting for the works to finish
1. switch to the new index
1. release the index lock

The fact that this process requires the index to be locked while the process 
runs means that we prefer to run it out of hours so that it doesn't block
the insertion of new content.

The index locking is required so that document edits during the reindex process 
are blocked from writing to the old index, as they would then be discarded. The
lock blocks the write until the process has completed and switched to the new index.

This in turn means we need to create a new index to write the updated popularity
data to, as the old index is currently locked. 

The code is quite complicated as it has to manage a threaded workload, which
is difficult to test and reason about.

As part of building the new `govuk` index, we want to simplify this process and 
ideally avoid the index locking.

## Decision

### Leverage external versioning to avoid locking

We have previously documented the decision to implement external versioning. As 
a result of this functionality, we can rethink how we do our overnight processing.

If we don't use index locking and switching and instead just overwrite the existing
document with a copy of itself with the updated popularity figure, the following 
scenario outlines the different outcome. 

> Given we have a piece of content called `DocumentA` which is currently in
the index with a version of `5`. The popularity update process will create a job 
to update this content, let's call this `job-A` with the popularity figure for 
today, let's call this `pop-today`.
>
> If we get an update on `DocumentA` while the popularity update process is running,
> let's call this `update-A`, `update-A` will be generated with a popularity figure
> equal to `pop-today`, the same as what is in `job-A`.
> 
> This can result in one of two things occurring:
>
> * `update-A` occurs before `job-A` - in this case `job-A` will be ignored as it
> is for an earlier version of `DocumentA`, leaving the values from `update-A` in
> the search index
> * `job-A` occurs before `update-A` - in this case both updates will occur, 
> leaving the values from `update-A` in the search index
