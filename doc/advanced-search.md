# Advanced search

Advanced search is a custom finder available at the path `/search/advanced`.

Rummager assumes the responsibility of publishing the Advanced Search Finder via a rake task.

The rummager task `publishing_api:publish_advanced_search_finder` uses the contents of `config/advanced-search.yml`
as the basis of a payload which is drafted and published to the Publishing API.
