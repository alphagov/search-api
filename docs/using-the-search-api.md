# Using the search API

## Quickstart

The user entered search query is specified using the `q` parameter. This should be exactly what the user typed into a search box, encoded as UTF-8. Any well-formed UTF-8 values are allowed.

```
curl 'https://www.gov.uk/api/search.json?q=taxes&count=1'
```

```json
{
    "facets": {},
    "results": [
        {
            "_id": "/vehicle-tax",
            "description": "Renew or tax your vehicle for the first time, apply online, by phone or at the Post Office",
            "document_type": "edition",
            "es_score": 0.191312,
            "format": "transaction",
            "index": "govuk",
            "link": "/vehicle-tax",
            "organisations": [
                {
                    "acronym": "DVLA",
                    "content_id": "70580624-93b5-4aed-823b-76042486c769",
                    "link": "/government/organisations/driver-and-vehicle-licensing-agency",
                    "organisation_state": "live",
                    "slug": "driver-and-vehicle-licensing-agency",
                    "title": "Driver and Vehicle Licensing Agency"
                }
            ],
            "public_timestamp": "2014-12-09T16:21:03+00:00",
            "title": "Tax your vehicle"
        }
    ],
    "start": 0,
    "suggested_queries": [],
    "total": 45118
}
```

## Pagination
Pagination is controlled using the `start`, `count`, and `order` parameters.

 - `start`: (single integer) Position in search result list to start returning
   results (0-based)  If the `start` offset is greater than the number of
   matching results, no results will be returned (but also no error will be
   returned).

 - `count`: (single integer) Maximum number of search results to return.  If
   insufficient documents match, as many as possible are returned (subject to
   the supplied `start` offset).  This may be set to 0 to return no results
   (which may be useful if only, say, facet values are wanted).  Setting this
   to 0 will reduce processing time.

 - `order`: (single string) The sort order.  A field name, with an optional
   preceding "`-`" to sort in descending order.  If not specified, sort order
   is relevance.  Only some fields can be sorted on - an HTTP 422 error will be
   returned if the requested field is not a valid sort field.


## Error reporting

The search API supports many query string parameters.  It validates
parameters strictly - any unknown parameters, or parameters with invalid
options, will cause an HTTP 422 error.  This means that typos do not make the
API silently return the wrong results, and new features can be added to the API
without changing what existing clients see.

## Returning specific document fields

See the [field reference](/config/schema/field_definitions.json) for a list of all fields returned by the search API.

Only a few fields are returned by default. You can override the fields returned using the `fields` parameter. For example:

```
https://www.gov.uk/api/search.json?q=passport&fields=mainstream_browse_pages&fields=title
```

Note that query parameters which are repeated may be specified in standard HTTP
style (ie, `name=value&name=value`, where the same name may be used multiple
times), or in Ruby/PHP array style (ie, `name[]=value&name[]=value`).

## Using faceted search parameters
You can use field prefixes such as `filter_<foo>`, `reject_<foo>` and `aggregate_<foo>` to further filter search results, for example:

```
https://www.gov.uk/api/search.json?filter_format=statistics_announcement&fields=title,link,format,rendering_app
```

You can read more in the [faceted search guide](https://docs.publishing.service.gov.uk/apps/search-api/public-api/faceted-search).


## Other parameters
- `ab_tests`: a/b test with selected variant type. This allows test to be configured
  from upstream apps.

  Each a/b test name should be followed by a ':' and then the variant type to
  be used. If multiple a/b test setting are being passed in they should be
  comma separated.

  No validation is done to ensure the a/b test name provided is current implemented.

- `c`: does nothing. By setting it to unique string, you can
  use it to bypass caching when testing.
