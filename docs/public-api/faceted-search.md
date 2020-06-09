# Faceted search

You can build [faceted search interfaces](https://alistapart.com/article/design-patterns-faceted-navigation) using the search API's `filter`/`reject` and `aggregate` parameters.

## Example

Pass the `aggregate_organisations` parameter to the search API to get a list of organisations, and the number of documents published by each of them.

```
https://www.gov.uk/api/search.json?count=0&aggregate_organisations=2
```

```json
"aggregates": {
  "organisations": {
    "options": [
      {
        "value": {
          "title": "HM Revenue & Customs",
            "content_id": "6667cce2-e809-4e21-ae09-cb0bdc1ddda3",
            "acronym": "HMRC",
            "link": "/government/organisations/hm-revenue-customs",
            "slug": "hm-revenue-customs",
            "organisation_type": "non_ministerial_department",
            "organisation_state": "live"
        },
          "documents": 160621
      },
      {
        "value": {
          "title": "Department for International Development",
          "content_id": "db994552-7644-404d-a770-a2fe659c661f",
          "acronym": "DFID",
          "link": "/government/organisations/department-for-international-development",
          "slug": "department-for-international-development",
          "organisation_type": "ministerial_department",
          "organisation_state": "live"
        },
        "documents": 66490
      }
    ],
      "documents_with_no_value": 20186,
      "total_options": 1032,
      "missing_options": 1029,
      "scope": "exclude_field_filter"
  }
}
```

After the user selects some organisations, you can pass a `filter_organisations` parameter for each selected value:

```
https://www.gov.uk/api/search.json?count=1&filter_organisations=hm-revenue-customs&aggregate_organisations=2
```

```json
{
  "results":[
    {
      "description":"The home of HM Revenue & Customs on GOV.UK. We are the UK’s tax, payments and customs authority, and we have a vital purpose: we collect the money that pays for the UK’s public services and help families and individuals with targeted financial support. We do this by being impartial and increasingly effective and efficient in our administration. We help the honest majority to get their tax right and make it hard for the dishonest minority to cheat the system.",
      "format":"organisation",
      "link":"/government/organisations/hm-revenue-customs",
      "organisations":[
        {
          "title":"HM Revenue & Customs",
          "content_id":"6667cce2-e809-4e21-ae09-cb0bdc1ddda3",
          "acronym":"HMRC",
          "link":"/government/organisations/hm-revenue-customs",
          "slug":"hm-revenue-customs",
          "organisation_type":"non_ministerial_department",
          "organisation_state":"live"
        }
      ],
      "slug":"hm-revenue-customs",
      "title":"HM Revenue & Customs",
      "index":"government",
      "es_score":null,
      "_id":"/government/organisations/hm-revenue-customs",
      "elasticsearch_type":"edition",
      "document_type":"edition"
    }
  ],
  "total":84288,
  "start":0,
  "aggregates": [...]
}
```

## Filtering parameters
You can filter search results using any of the filter_<field name> or reject_<field name> query parameters.

- filter is used to only return documents that match a value
- reject excludes documents that match a value

Multiple values may be given, and filters may be specified for multiple fields at once. The filters are grouped by field name; documents will only be returned if they match all of these filter groups, and they will be considered to match a filter group if any of the individual filters in that group match (ie, only one of the values specified for a field needs to match, but all fields with any filters specified must match at least one value).

The special value `_MISSING` may be specified as a filter value - this will match documents where the field is not present at all.

For string fields, values are the field value to match.

For date fields, values are date ranges. These are specified as comma separated lists of key:value parameters, where key is one of `from` or `to`, and the value is an ISO formatted date (with no timezone). UTC is assumed for all dates. Date ranges are inclusive of their endpoints.

For example: `from:2014-04-01 00:00,to:2014-04-02 00:00` is a range for 24 hours from midnight at the start of April the 1st 2014, including midnight that day or the following day.

Currently, it is not permitted to specify multiple values for a date field filter.

Only some fields can be filtered on - an HTTP 422 error will be returned if the requested field is not a value sort field.

If a filter and a reject are specified for the same field, an HTTP 422 error will be returned. However, it is valid to specify a reject for some fields and a filter for others - documents will be required to match the criteria on both fields.

For filtering multivalued fields such as `part_of_taxonomy_tree`, you can use an additional operation:

- `filter_any_<field name>` returns documents that contain at least one of the specified values for the field name.
- `filter_all_<field name>` returns documents that contain all of the specified values for the field name.
- `reject_any_<field name>` same as filter_any, but rejects documents instead.
- `reject_all_<field name>` same as filter_all, but rejects documents instead.

This can be useful to find all documents that are tagged to two taxons (use `filter_all_`), or documents that have been tagged to one of two taxons (use `filter_any_`)
## Aggregation parameters

Aggregations look at all the values of a a field and count up the number of times each one appears in documents matching the search.

You can include facets in any search by specifying one of the aggregate_<field name> query parameters.

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
