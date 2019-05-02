# Advanced search

Advanced search is a custom finder available at the path `/search/advanced`.

Search API assumes the responsibility of publishing the Advanced Search Finder via a rake task.

The Search API task `FINDER_CONFIG=advanced-search.yml publishing_api:publish_finder`
 uses the specified config file as the basis of a payload which is drafted and published to the Publishing API.
