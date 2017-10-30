# Moving a format to the new indexing process

These are the steps to move formats to the new indexing process described in [ADR 004 - Transition mainstream formats to a Publishing API derived search index
](./arch/adr-004-transition-mainstream-to-publishing-api-index.md)

Note: if you're adding a brand new format, see [make a new document type available to search](https://docs.publishing.service.gov.uk/manual/make-a-new-document-type-available-to-search.html) instead.

## Get the data in sync on integration

1. [Optional] run the check to see the starting state of the `govuk` index:

  ```rake rummager:compare_govuk[<format>]```

2. Mark the format as `indexable` in `migrated_formats.yaml` and deploy to integration.

    This makes Rummager update the `govuk` index when content is published or unpublished.

3. Delete any existing data from the `govuk` index for the unmigrated format.
   This makes sure that it only contains the data you send to it from the publishing api.

   ``` rake delete:by_format[<format>,govuk]```

4. Resend from publishing API on integration

   ``` rake queue:requeue_document_type[<format>]```

   If nothing happens, check the sidekiq logs for the Rummager govuk index worker.

   You can also monitor the resending using the Rummager deployment dashboard or the [elasticsearch dashboard](https://grafana.integration.publishing.service.gov.uk/dashboard/db/elasticsearch-activity).

5. Rerun the comparison

   ```rake rummager:compare_govuk[<format>]```

If the comparison shows significant differences between the old index and `govuk`, change the presenter in Rummager and repeat steps 4-5 until it looks consistent.

We expect some differences, for example
- small changes to `indexable_content`
- fields being populated that weren't there before
- some documents removed (if they are unpublished in the publishing app)
- some documents added (if they are published in the publishing app)

If you want to edit/debug the comparer script, it's helpful to run this step locally, using an SSH tunnel to the integration elasticsearch.

`ssh -L9200:localhost:9200 rummager-elasticsearch-1.api.integration`

## Deploy to production
When it looks consistent on integration, deploy to production with the format as `indexable` in `migrated_formats.yaml`.

You will need to run steps 3-4 above on each environment.

Verify that the new indexing process runs without errors for a few days, including the nightly popularity update.

## Mark the format as `migrated` in `migrated_formats.yaml`
This will cause Rummager to use the new index for queries.

Test all search pages/finders that can show the format, and run the search healthcheck.

If anything goes wrong, roll back to "indexed".

## Remove the indexing code from the publishing app
Once everything is working, the publishing app doesn't need to integrate
with rummager any more.
