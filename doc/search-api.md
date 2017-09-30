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
            "index": "mainstream",
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

See the [field reference](https://docs.publishing.service.gov.uk/apis/search/fields.html) for a list of all fields returned by the search API.

Only a few fields are returned by default. You can override the fields returned using the `fields` parameter. For example:

```
https://www.gov.uk/api/search.json?q=passport&fields=mainstream_browse_pages&fields=title
```

Note that query parameters which are repeated may be specified in standard HTTP
style (ie, `name=value&name=value`, where the same name may be used multiple
times), or in Ruby/PHP array style (ie, `name[]=value&name[]=value`).

## Building facetted search with filters and aggregations

### Filter parameters
You can filter search results using any of the filter_<field name> or reject_<field name> query parameters.

- filter is used to only return documents that match a value
- reject excludes documents that match a value

Multiple values may be given, and filters may be specified for multiple fields at once. The filters are grouped by field name; documents will only be returned if they match all of these filter groups, and they will be considered to match a filter group if any of the individual filters in that group match (ie, only one of the values specified for a field needs to match, but all fields with any filters specified must match at least one value).

The special value `_MISSING` may be specified as a filter value - this will match documents where the field is not present at all.

For string fields, values are the field value to match.

For date fields, values are date ranges. These are specified as comma separated lists of key:value parameters, where key is one of `from` or `to`, and the value is an ISO formatted date (with no timezone). UTC is assumed for all dates handled by rummager. Date ranges are inclusive of their endpoints.

For example: `from:2014-04-01 00:00,to:2014-04-02 00:00` is a range for 24 hours from midnight at the start of April the 1st 2014, including midnight that day or the following day.

Currently, it is not permitted to specify multiple values for a date field filter.

Only some fields can be filtered on - an HTTP 422 error will be returned if the requested field is not a value sort field.

If a filter and a reject are specified for the same field, an HTTP 422 error will be returned. However, it is valid to specify a reject for some fields and a filter for others - documents will be required to match the criteria on both fields.

### Aggregation parameters

Aggregations look at all the values of a a field and count up the number of times each one appears in documents matching the search.

You can include facets in any search by specifying one of the aggregate_<field name> query parameters.

For example, to group by organisation:

```
curl 'https://www.gov.uk/api/search.json?count=0&aggregate_organisations=3'
```

```json
{
    "aggregates": {
        "organisations": {
            "documents_with_no_value": 15996,
            "missing_options": 1033,
            "options": [
                {
                    "documents": 80911,
                    "value": {
                        "acronym": "HMRC",
                        "content_id": "6667cce2-e809-4e21-ae09-cb0bdc1ddda3",
                        "link": "/government/organisations/hm-revenue-customs",
                        "organisation_state": "live",
                        "slug": "hm-revenue-customs",
                        "title": "HM Revenue & Customs"
                    }
                },
                {
                    "documents": 34463,
                    "value": {
                        "acronym": "DFID",
                        "content_id": "db994552-7644-404d-a770-a2fe659c661f",
                        "link": "/government/organisations/department-for-international-development",
                        "organisation_state": "live",
                        "slug": "department-for-international-development",
                        "title": "Department for International Development"
                    }
                },
                {
                    "documents": 13469,
                    "value": {
                        "acronym": "FCO",
                        "content_id": "9adfc4ed-9f6c-4976-a6d8-18d34356367c",
                        "link": "/government/organisations/foreign-commonwealth-office",
                        "organisation_state": "live",
                        "slug": "foreign-commonwealth-office",
                        "title": "Foreign & Commonwealth Office"
                    }
                }
            ],
            "scope": "exclude_field_filter",
            "total_options": 1036
        }
    },
    "results": [],
    "start": 0,
    "suggested_queries": [],
    "total": 301755
}
```

The value of this parameter is a comma separated list of options; the first option in the list is an integer which controls the requested number of distinct field values to be returned for the field. Regardless of the number set here, a value will be returned for any filter which is in place on the field. This may cause the requested number of values to be exceeded.

Subsequent options are optional, and are represented as colon separated key:value pairs (note, colon separated instead of comma, since commas are used to separate options).


 - `scope`: One of `all_filters` and `exclude_field_filter` (the default).

   If set to `all_filters`, the aggregate counts are made after applying all the
   filters.  If set to `exclude_field_filter`, the aggregate counts are made
   after applying all filters _except_ for those applied to the field that
   the aggregates are being counted for.  This is a convenient option for
   calculating values to show in common interfaces which use aggregate for
   narrowing down search results.

 - `order`: Colon separated list of ordering types.

   The available ordering types are:

    - `filtered`: whether the value is used in an active filter.  This can be
used to sort such that the values which are being filtered on come
first.
    - `count`: order by the number of documents in the search matching the
facet value.
    - `value`: sort by value if the field values are string, sort by the
`title` field in the value object if the value is an object.  Sorting
is case insensitive in either case.
    - `value.slug`: the slug in the facet value object
    - `value.link`: the link in the facet value object
    - `value.title`: the title in the facet value object (case insensitive)

   Each ordering may be preceded by a "-" to sort in descending order.
   Multiple orderings can be specified, in priority order, separated by a
   colon.  The default ordering is "filtered:-count:slug".

 - `examples`: integer number of example values to return

   This causes facet values to contain an "examples" hash as an additional
   field, which contains details of example documents which match the query.
   The examples are sorted by decreasing popularity.  An example facet value
   in a response with this option set as "examples:1" might look like:

      "value" => {
        "slug" => "an-example-facet-slug",
        "example_info" => {
          "total" => 3,  # The total number of matching examples
          "examples" => [
            {"title" => "Title of the first example", "link" => "/foo"},
          ],
        }
      }

 - `example_scope`: `global` or `query`.  If the `examples` option is supplied, the
   `example_scope` option must be supplied too.

   The value of `global` causes the returned examples to be taken from all
   documents in which the facet field has the given slug.

   The value of `query` causes the returned examples to be taken only from
   those documents which match the query (and all filters).

 - `example_fields`: colon separated list of fields.

   If the examples option is supplied, this lists the fields which are
   returned for each example.  By default, only a small number of fields are
   returned for each.

## Other parameters
- `ab_tests`: a/b test with selected variant type. This allows test to be configured
  from upstream apps.

  Each a/b test name should be followed by a ':' and then the variant type to
  be used. If multiple a/b test setting are being passed in they should be
  comma separated.

  No validation is done to ensure the a/b test name provided is current implemented.

- `c`: does nothing. By setting it to unique string, you can
  use it to bypass caching when testing.
