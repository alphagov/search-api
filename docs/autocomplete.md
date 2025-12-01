# Autocomplete

Autocomplete is a feature that suggests search phrases as you type. In search-api autocomplete is based on popularity data from GA4.

## Does autocomplete work?

No. Not for users.

Autocomplete was added as an experiment at the close of 2019. However, it doesn't appear that this endpoint was ever added to finder-frontend so it's unlikely that it has been tested with real users.

It is possible to see autocomplete suggestions from elasticsearch in the payload but these suggestions are not shown to the user in the supergroup or specialist finders.

As there were no associated running costs, the endpoint was left in search-api. 

## How do I see autocomplete suggestions for a query?

To see autocomplete suggestions you must add `suggest=autocomplete` to the query string. For example: 

In production visit: 
<https://www.gov.uk/api/search.json?q=tax&suggest=autocomplete&count=1>

Or locally go to:
<http://search-api.dev.gov.uk/search?q=tax&suggest=autocomplete&count=1>

You should see something similar to:

```json
"suggested_autocomplete": [
  "Tax your vehicle",
  "Tax-Free Childcare",
  "Tax overpayments and underpayments",
  "Tax codes",
  "Tax on savings interest",
  "Tax your vehicle without a vehicle tax reminder",
  "Tax on dividends",
  "Tax when you sell property"
],
```

<details>
<summary>Full example response</summary>

```json
{
  "results": [
    {
      "description": "Renew or tax your vehicle for the first time using a reminder letter, your log book or the green 'new keeper' slip - and how to tax if you do not have any documents",
      "format": "transaction",
      "link": "/vehicle-tax",
      "organisations": [
        {
          "organisation_type": "executive_agency",
          "organisation_state": "live",
          "acronym": "DVLA",
          "content_id": "70580624-93b5-4aed-823b-76042486c769",
          "parent_organisations": [
            "department-for-transport"
          ],
          "link": "/government/organisations/driver-and-vehicle-licensing-agency",
          "title": "Driver and Vehicle Licensing Agency",
          "analytics_identifier": "EA74",
          "organisation_crest": "single-identity",
          "organisation_brand": "department-for-transport",
          "logo_formatted_title": "Driver & Vehicle\r\nLicensing\r\nAgency",
          "public_timestamp": "2023-08-16T11:17:43.000+01:00",
          "slug": "driver-and-vehicle-licensing-agency"
        }
      ],
      "public_timestamp": "2017-12-07T12:54:39Z",
      "title": "Tax your vehicle",
      "world_locations": [],
      "topical_events": [],
      "organisation_content_ids": [
        "70580624-93b5-4aed-823b-76042486c769"
      ],
      "expanded_organisations": [
        {
          "organisation_type": "executive_agency",
          "organisation_state": "live",
          "acronym": "DVLA",
          "content_id": "70580624-93b5-4aed-823b-76042486c769",
          "parent_organisations": [
          "department-for-transport"
          ],
          "link": "/government/organisations/driver-and-vehicle-licensing-agency",
          "title": "Driver and Vehicle Licensing Agency",
          "analytics_identifier": "EA74",
          "organisation_crest": "single-identity",
          "organisation_brand": "department-for-transport",
          "logo_formatted_title": "Driver & Vehicle\r\nLicensing\r\nAgency",
          "public_timestamp": "2023-08-16T11:17:43.000+01:00",
          "slug": "driver-and-vehicle-licensing-agency"
        }
      ],
      "index": "govuk",
      "es_score": 17.194002,
      "_id": "/vehicle-tax",
      "elasticsearch_type": "edition",
      "document_type": "edition"
    }
  ],
  "total": 79464,
  "start": 0,
  "aggregates": {},
  "suggested_queries": [],
  "suggested_autocomplete": [
    "Tax your vehicle",
    "Tax-Free Childcare",
    "Tax overpayments and underpayments",
    "Tax codes",
    "Tax on savings interest",
    "Tax your vehicle without a vehicle tax reminder",
    "Tax on dividends",
    "Tax when you sell property"
  ],
  "es_cluster": "A"
}
```
</details>


## How are autocomplete suggestions added to elasticsearch?

Autocomplete suggestions are added to elasticsearch via the `update_popularity` rake task. Currently this job runs [once per day]. The title of the page and a "weighting" are passed to elasticsearch (See [PopularityJob]).

You can see the payload that is sent to elasticsearch by querying the internal [content-api]

For example visiting <http://search-api.dev.gov.uk/content?link=/search/services> will show the following at the bottom of the payload:

```json
"autocomplete": {
  "input": "Services",
  "weight": 234796
}
```
<details>
<summary>Full payload</summary>

```json
{
  "index": "govuk",
  "raw_source": {
    "content_id": "f6d779ac-5f78-413d-a1ff-da391944e6ec",
    "content_purpose_document_supertype": "navigation",
    "content_purpose_subgroup": "other",
    "content_purpose_supergroup": "other",
    "content_store_document_type": "finder",
    "description": "Find services from government",
    "document_type": "edition",
    "email_document_supertype": "other",
    "facet_groups": [],
    "facet_values": [],
    "first_published_at": "2019-02-14T14:55:27Z",
    "format": "finder",
    "government_document_supertype": "other",
    "is_historic": false,
    "is_political": false,
    "is_withdrawn": false,
    "link": "/search/services",
    "mainstream_browse_page_content_ids": [],
    "mainstream_browse_pages": [],
    "navigation_document_supertype": "other",
    "organisation_content_ids": [],
    "organisations": [],
    "part_of_taxonomy_tree": [],
    "people": [],
    "policy_groups": [],
    "popularity": 0.0012836970474967907,
    "popularity_b": 234796,
    "primary_publishing_organisation": [],
    "public_timestamp": "2020-03-25T11:59:34Z",
    "updated_at": "2020-03-25T11:59:35.444+00:00",
    "publishing_app": "search-api",
    "role_appointments": [],
    "roles": [],
    "rendering_app": "finder-frontend",
    "search_user_need_document_supertype": "government",
    "specialist_sectors": [],
    "taxons": [],
    "title": "Services",
    "topic_content_ids": [],
    "topical_events": [],
    "user_journey_document_supertype": "finding",
    "view_count": 14375,
    "world_locations": [],
    "autocomplete": {
      "input": "Services",
      "weight": 234796
    }
  }
}
```
</details>

## What does the autocomplete payload returned from elasticsearch look like?

If you set your logging level to DEBUG you should be able to see the response from elasticsearch that includes any autocomplete suggestions.

For example if you visit <http://search-api.dev.gov.uk/search?q=tax&suggest=autocomplete&count=1> locally, you should see something similar to:

<details>
<summary>Full response from elasticsearch</summary>

```ruby
{
  "took" => 613, 
  "timed_out" => false, 
  "_shards" => {
    "total" => 9, "successful" => 9, "skipped" => 0, "failed" => 0
  }, "
  hits" => {
    "total" => 49659, 
    "max_score" => 1000016.56, 
    "hits" => [{
      "_index" => "govuk-2023-04-02t21-35-06z-a32d9f2c-8cae-490f-9cc6-f639ba022068",
      "_type" => "generic-document",
      "_id" => "/vehicle-tax",
      "_score" => 1000016.56,
      "_source" => {
        "link" => "/vehicle-tax", 
        "format" => "transaction", 
        "organisation_content_ids" => ["70580624-93b5-4aed-823b-76042486c769"], 
        "description" => "Renew or tax your vehicle for the first time using a reminder letter, your log book or the green 'new keeper' slip - and how to tax if you do not have any documents", "title" => "Tax your vehicle", 
        "mainstream_browse_page_content_ids" => ["c4cbf7d1-c44e-4f47-b2c8-380e0609f8b0"], "organisations" => ["driver-and-vehicle-licensing-agency"], 
        "updated_at" => "2023-04-26T11:01:13.484+01:00", 
        "popularity" => 0.058823529411764705, 
        "public_timestamp" => "2017-12-07T12:54:39Z", 
        "indexable_content" => "Tax your car, motorcycle or other vehicle using a reference number from:\n\na recent reminder (V11) or ‘last chance’ warning letter from DVLA\n\nyour vehicle log book (V5C) - it must be in your name\n\nthe green ‘new keeper’ slip from a log book if you’ve just bought it\n\nIf you do not have any of these documents, you’ll need to apply for a new log book.\n\nYou can pay by debit or credit card, or Direct Debit.\n\nYou must tax your vehicle even if you do not have to pay anything, for example if you’re exempt because you’re disabled.\n\nYou’ll need to meet all the legal obligations for drivers before you can drive.\n\nThis service is also available in Welsh.\n\n\n\nChange your car’s tax class to or from ‘disabled’\n\nYou may need to change your vehicle’s tax class, for example if either:\n\nyour car was previously used by a disabled person\n\nyou’re disabled and taxing your car for the first time\n\nYou can only apply at a Post Office.", 
        "topical_events" => [], 
        "document_type" => "edition", 
        "world_locations" => []
      }
    }]
  }, 
  "autocomplete" => {
    "suggested_autocomplete" => [{
      "text" => "tax",
      "offset" => 0,
      "length" => 3,
      "options" => [{
        "text" => "Taxpayers given more",
        "_index" => "government-2021-08-12t23-23-51z-f0d661a8-7769-461e-8136-53c5d5c8d6a7",
        "_type" => "generic-document",
        "_id" => "/government/news/taxpayers-given-more-time-for-voluntary-national-insurance-contributions",
        "_score" => 234584.0,
        "_source" => {
          "autocomplete" => {
            "input" => "Taxpayers given more time for voluntary National Insurance contributions", "weight" => 234584
          }
        }
      }, 
      {
        "text" => "Tax-free allowances ",
        "_index" => "detailed-2022-10-26t19-54-59z-342f3da4-1159-4433-898f-089272c6c25d",
        "_type" => "generic-document",
        "_id" => "/guidance/tax-free-allowances-on-property-and-trading-income",
        "_score" => 233734.0,
        "_source" => {
          "autocomplete" => {
            "input" => "Tax-free allowances on property and trading income", "weight" => 233734
          }
        }
      }, 
      {
        "text" => "Tax treaties",
        "_index" => "government-2021-08-12t23-23-51z-f0d661a8-7769-461e-8136-53c5d5c8d6a7",
        "_type" => "generic-document",
        "_id" => "/government/collections/tax-treaties",
        "_score" => 233235.0,
        "_source" => {
          "autocomplete" => {
            "input" => "Tax treaties", "weight" => 233235
          }
        }
      }, 
      {
        "text" => "Tax relief for resid",
        "_index" => "detailed-2022-10-26t19-54-59z-342f3da4-1159-4433-898f-089272c6c25d",
        "_type" => "generic-document",
        "_id" => "/guidance/changes-to-tax-relief-for-residential-landlords-how-its-worked-out-including-case-studies",
        "_score" => 231379.0,
        "_source" => {
          "autocomplete" => {
            "input" => "Tax relief for residential landlords: how it's worked out", "weight" => 231379
          }
        }
      }, 
      {
        "text" => "Taxation of environm",
        "_index" => "government-2021-08-12t23-23-51z-f0d661a8-7769-461e-8136-53c5d5c8d6a7",
        "_type" => "generic-document",
        "_id" => "/government/consultations/taxation-of-environmental-land-management-and-ecosystem-service-markets",
        "_score" => 231088.0,
        "_source" => {
          "autocomplete" => {
            "input" => "Taxation of environmental land management and ecosystem service markets", "weight" => 231088
          }
        }
      }, 
      {
        "text" => "Tax credits: work ou",
        "_index" => "govuk-2023-04-02t21-35-06z-a32d9f2c-8cae-490f-9cc6-f639ba022068",
        "_type" => "generic-document",
        "_id" => "/childcare-costs-for-tax-credits",
        "_score" => 229788.0,
        "_source" => {
          "autocomplete" => {
            "input" => "Tax credits: work out your childcare costs", "weight" => 229788
          }
        }
      }, 
      {
        "text" => "Tax avoidance - don'",
        "_index" => "government-2021-08-12t23-23-51z-f0d661a8-7769-461e-8136-53c5d5c8d6a7",
        "_type" => "generic-document",
        "_id" => "/government/case-studies/tax-avoidance-dont-get-caught-out",
        "_score" => 229608.0,
        "_source" => {
          "autocomplete" => {
            "input" => "Tax avoidance - don't get caught out", "weight" => 229608
          }
        }
      }, 
      {
        "text" => "Tax structure and pa",
        "_index" => "government-2021-08-12t23-23-51z-f0d661a8-7769-461e-8136-53c5d5c8d6a7",
        "_type" => "generic-document",
        "_id" => "/government/collections/tax-structure-and-parameters-statistics",
        "_score" => 229231.0,
        "_source" => {
          "autocomplete" => {
            "input" => "Tax structure and parameters statistics", "weight" => 229231
          }
        }
      }]
    }]
  }
}
```
</details>


[once per day]: https://github.com/alphagov/govuk-helm-charts/blob/56f522f6722ba6a4e713ee852f2b170f93cbeafc/charts/app-config/values-production.yaml#L2914
[PopularityJob]: https://github.com/alphagov/search-api/blob/37281b48495f58dedb5aad58ce8fc42cfdae6159/lib/govuk_index/popularity_job.rb#L39-L41
[content-api]: https://github.com/alphagov/search-api/blob/37281b48495f58dedb5aad58ce8fc42cfdae6159/docs/content-api.md
