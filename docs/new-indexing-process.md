# Moving a format to the new indexing process

These are the steps to move formats to the new indexing process described in [ADR 004 - Transition mainstream formats to a Publishing API derived search index
](./arch/adr-004-transition-mainstream-to-publishing-api-index.md)

Note: if you're adding a brand new format, see [make a new document type available to search](https://docs.publishing.service.gov.uk/manual/make-a-new-document-type-available-to-search.html) instead.

## Ensure the document type is migrated to publishing API
The publishing app should already notify the publishing API when documents are published and unpublished.

Example PRs for [adding a new document type](https://docs.publishing.service.gov.uk/manual/add-a-new-document-type.html):

- [Add external_content schema and document type](https://github.com/alphagov/govuk-content-schemas/pull/690)
- [Publish recommended links to publishing API](https://github.com/alphagov/search-admin/pull/97)
- [Add rake task for publishing all external links to the publishing API](https://github.com/alphagov/search-admin/pull/100/files)

Ensure that all fields the publishing app currently sends to Search API are included in the payload send to publishing API. If anything is missing, you'll need to update the publishing app and content schemas, and then re-publish existing content to the publishing API.

You may also want to clean up other inconsistencies before changing the indexing method.

Example PRs:

- [Prepare for moving to rummager](https://github.com/alphagov/calendars/pull/160/files)
- [Ensure we pass the description text to publishing API](https://github.com/alphagov/calendars/pull/162/files)

## Add the format to the list in `lib/learn_to_rank/format_enums.rb`

We take format into account in our machine learning, which means we
need a mapping from formats to unique numbers.

## Update the presenter to handle the new format
You'll need to update the elasticsearch presenter in Search API so that it handles any fields which are not yet used by other formats in the govuk index.

Fields that are common to multiple document types should be handled in a consistent way by Search API. Don't add in special cases without good reason, even if the publishing app used to do something different.

This is especially true for key fields like `title`, `description`, and `indexable_content`, although in some cases we do prefix titles so that similar looking content is distinguishable.

Example PRs:

- [Make policies indexable](https://github.com/alphagov/search-api/pull/1053)

## Get the data in sync on integration

1. Remove the format from as `non_indexable` in `migrated_formats.yaml` and deploy to integration.

    This makes Search API update the `govuk` index when content is published or unpublished.

1. Delete any existing data from the `govuk` index for the unmigrated format.
   This makes sure that it only contains the data you send to it from the publishing api.

   ``` rake delete:by_format[<format>,govuk]```

1. Resend from publishing API on integration

   ``` rake queue:requeue_document_type[<format>]```

   If nothing happens, check the sidekiq logs for the Search API govuk index worker.

   You can also monitor the resending using the Search API deployment dashboard or the [elasticsearch dashboard](https://grafana.integration.publishing.service.gov.uk/dashboard/file/search_api_elasticsearch.json).

## Deploy to production
When it looks consistent on integration, deploy to production.

You will need to run the steps above on each environment.

Verify that the new indexing process runs without errors for a few days.

## Mark the format as `migrated` in `migrated_formats.yaml`
This will cause Search API to use the new index for queries.

Test all search pages/finders that can show the format, and run the search healthcheck.

## Remove the indexing code from the publishing app
Once everything is working, the publishing app doesn't need to integrate
with Search API any more.

Example PRs:

- [Stop collections publishing to rummager](https://github.com/alphagov/collections-publisher/pull/259)
