# Content in the search index and where it comes from

For an overview view of the sorts of content that are available, see [Document types on GOV.UK](https://docs.publishing.service.gov.uk/document-types.html).

## Whitehall

This is what most publishers use to publish. Content appears on the ["inside government" part of GOV.UK](https://www.gov.uk/government/publications). There are 200,000 documents.

Implemented in [searchable.rb](https://github.com/alphagov/whitehall/blob/master/app/models/searchable.rb).

## Other publishing apps

Most publishing apps, such as publisher and specialist-publisher, do not send
content to Search API directly. Instead, they publish content to the
[publishing-api][publishing_api] which adds the content to a notifications queue
to be ingested by search-api.

See [ADR 001][adr_001] for more details on this approach.

[publishing_api]: https://github.com/alphagov/publishing-api
[adr_001]: https://github.com/alphagov/search-api/blob/master/doc/arch/adr-001-use-of-both-rabbitmq-and-sidekiq-queues.md

## Search admin
Admin for GOV.UK search. Publishes "recommended links" to Search API,
so we can show external links in search results; and "best bets", so
selected search results can be artificially boosted to the top of the
list.

Implemented in [elastic_search_recommended_link.rb](https://github.com/alphagov/search-admin/blob/master/app/models/elastic_search_recommended_link.rb) and [rummager_saver.rb](https://github.com/alphagov/search-admin/blob/master/app/services/rummager_saver.rb).
