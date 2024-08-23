# Using the search API

Search API is publicly accessible at <https://www.gov.uk/api/search.json>, and responds to different URL parameters, explained below. Parameters are strictly validated: if Search API encounters any unknown parameters (or known parameters but with invalid values) it returns a HTTP 422 error.

## Examples

Simple search query:

<https://www.gov.uk/api/search.json?q=taxes&count=1>

Get the next result in the sequence by specifying `start=1`.

<https://www.gov.uk/api/search.json?q=taxes&count=1&start=1>

Or if we want to get the oldest match:

<https://www.gov.uk/api/search.json?q=taxes&count=1&order=public_timestamp>

Retrieve just the title and 'mainstream browse pages' of documents matching search term "passport":

<https://www.gov.uk/api/search.json?q=passport&fields=mainstream_browse_pages&fields=title>

Retrieve documents of a specific type:

<https://www.gov.uk/api/search.json?q=test&count=1&filter_format=transaction>

Retrieve documents for a given organisation:

<https://www.gov.uk/api/search.json?q=policy&count=1&filter_organisations=cabinet-office>

Retrieve documents for multiple organisations:

<https://www.gov.uk/api/search.json?q=policy&count=1&filter_organisations=cabinet-office&filter_organisations=home-office>

Retrieve documents associated with Cabinet Office but not with Government Digital Service:

<https://www.gov.uk/api/search.json?q=policy&count=1&filter_organisations=cabinet-office&reject_organisations=government-digital-service>

Find documents published within a certain date range:

<https://www.gov.uk/api/search.json?q=pig&count=1&filter_public_timestamp=from:2020-01-01,to:2020-12-31>

Aggregated/grouped search query (fetch list of organisations and the number of documents published by each of them):

```
https://www.gov.uk/api/search.json?count=0&aggregate_organisations=2
```

## URL parameters

### q

Search query. Any well-formed UTF-8 values are allowed.

### count

The `count` parameter limits the number of results returned (default: 10, maximum: 1500).
If insufficient documents match, as many as possible are returned (subject to the supplied [start](#start) offset).

This may be set to 0 to return no results (which may be useful if only, say, facet values are wanted). Setting this to 0 will reduce processing time.

### order

Defines the sort order. Takes a field name, with an optional preceding "`-`" to sort in descending order.
If not specified, results are ordered by relevance. Only some fields can be sorted on.

### start

The `start` parameter takes an integer, which is the position in the search result list to start returning results.
It uses a 0-based index.

If the `start` offset is greater than the number of matching results, no results will be returned (but also no error will be returned). `start` is used for implementing pagination.

### fields

Only a subset of fields are returned by default. You can override the fields returned using the `fields` parameter. Refer to the fields in [field_definitions.json](/config/schema/field_definitions.json).

Note that query parameters which are repeated may be specified in standard HTTP style (ie, `fields=value&fields=another-value`, where the same name may be used multiple times), or in Ruby/PHP array style (ie, `fields[]=value&fields[]=another-value`).

### filter_* / reject_*

You can pass a `filter_<field name>` URL parameter to return documents that match a value. For example, `filter_format=transaction` retrieves only `transaction` documents (see [Content schemas](/content-schemas.html) for possible values).

Equally, you can pass a `reject_<field name>` URL parameter to exclude documents that match that value.

Multiple values per filter/reject may be given (see [fields](#fields)), and multiple `filter_*`/`reject_*` parameters may be used in conjunction with one another.

The filters are grouped by field name: documents will only be returned if they match all of these filter groups, and they will be considered to match a filter group if any of the individual filters in that group match (ie, only one of the values specified for a field needs to match, but all fields with any filters specified must match at least one value). The special value `_MISSING` may be specified as a filter value - this will match documents where the field is not present at all.

`filter_*`/`reject_*` works with date fields too, although unlike string fields, it is not permitted to provide multiple values for a single date field filter. The date field filter value should be either a `from:<date>`, `to:<date>` or both (comma separated), where `<date>` is an ISO formatted date (with no timezone: UTC is assumed). Date ranges are inclusive: for example, `from:2014-04-01 00:00,to:2014-04-02 00:00` is a range of 24 hours from midnight at the start of April the 1st 2014. If the time is omitted, the `from:` parameter defaults to `00:00` and the `to:` parameter defaults to `23:59`, i.e. `from:2014-04-01,to:2014-04-02` covers a full 48 hour period.

### filter_any_* / filter_all_* / reject_any_* / reject_all_*

For filtering multivalued fields such as `part_of_taxonomy_tree`, you can use an additional operation:

- `filter_any_<field name>` returns documents that contain at least one of the specified values for the field name.
- `filter_all_<field name>` returns documents that contain all of the specified values for the field name.
- `reject_any_<field name>` same as filter_any, but rejects documents instead.
- `reject_all_<field name>` same as filter_all, but rejects documents instead.

This can be useful to find all documents that are tagged to two taxons (use `filter_all_`), or documents that have been tagged to one of two taxons (use `filter_any_`).

### aggregate_*

Aggregations look at all the values of a field and count up the number of times each one appears in documents matching the search. For example, the `aggregate_organisations` parameter will group search results by organisation, if it is set to a valid value.

The value of an `aggregate_*` parameter is a comma separated list of options:

- 'Limit' (required): an integer which controls the requested number of distinct field values to be returned for the field, e.g. `aggregate_organisations=10`. Regardless of the number set here, a value will be returned for any filter which is in place on the field. This may cause the requested number of values to be exceeded.

- `scope` (optional): either `exclude_field_filter` by default, or `all_filters`. If set to `all_filters`, the aggregate counts are made after applying all the filters. If set to `exclude_field_filter`, the aggregate counts are made after applying all filters _except_ for those applied to the field that the aggregates are being counted for. This is a convenient option for calculating values to show in common interfaces which use aggregate for narrowing down search results.

- `order` (optional): colon-separated list of ordering types. Multiple orderings can be specified, in priority order, and each can be preceded by a "`-`" to sort in descending order. The default ordering is `filtered:-count:slug`. The available ordering types are:
  - `filtered`: whether the value is used in an active filter.  This can be used to sort such that the values which are being filtered on come first.
  - `count`: order by the number of documents in the search matching the facet value.
  - `value`: sort by value if the field values are string, sort by the `title` field in the value object if the value is an object. Sorting is case insensitive in either case.
  - `value.slug`: the slug in the facet value object
  - `value.link`: the link in the facet value object
  - `value.title`: the title in the facet value object (case insensitive)

- `examples` (optional): integer number of example values to return. This causes facet values to contain an "examples" hash as an additional field, which contains details of example documents which match the query. The examples are sorted by decreasing popularity. An example facet value in a response with this option set as "`examples:1`" might look like:

    ```
      "value" => {
          "slug" => "an-example-facet-slug",
            "example_info" => {
              "total" => 3,  # The total number of matching examples
                "examples" => [
                {"title" => "Title of the first example", "link" => "/foo"},
              ],
            }
        }
    ```

- `example_scope` (required if `examples` is provided): either `global` or `query`.
  - `global` causes the returned examples to be taken from all documents in which the facet field has the given slug.
  - `query` causes the returned examples to be taken only from those documents which match the query (and all filters).

- `example_fields` (optional, and only used if `examples` is provided): colon-separated list of fields.
  If the examples option is supplied, this lists the fields which are returned for each example. By default, only a small number of fields are returned for each.

Example of aggregate query with multiple options: <https://www.gov.uk/api/search.json?count=0&aggregate_organisations=1,scope:all_filters,order:filtered:-count>

### ab_tests

The value of `ab_tests` should be whatever variant type you want to test (and can be configured from upstream apps).

Each a/b test name should be followed by a ':' and then the variant type to be used. If multiple a/b test setting are being passed in they should be comma separated.

No validation is done to ensure the a/b test name provided is currently implemented.

### c

The `c` parameter is used for cachebusting. Set the value to a unique string to bypass caching. It doesn't affect the search itself.