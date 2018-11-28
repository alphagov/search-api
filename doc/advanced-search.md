# Advanced search

Advanced search is a custom finder available at the path `/search/advanced`.

Rummager assumes the responsibility of publishing the Advanced Search Finder via a rake task.

The rummager task `DOCUMENT_FINDER_CONFIG=config/advanced-search.yml publishing_api:publish_document_finder`
 uses the specified config file as the basis of a payload which is drafted and published to the Publishing API.
