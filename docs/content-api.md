# Internal "content API"

## How to use

Internal to Search API, but can be queried by:

1. Opening a shell in the app container: `k exec -it deploy/search-api -- bash`
2. Curling the endpoint from within the container, e.g. `curl -XGET http://0.0.0:3000/content?link=/vehicle-tax`

## API methods

### `GET /content?link=/a-link`

Returns information about the search result with the specified link.

Example response:

```json
{
  "index": "govuk",
  "raw_source": {
    "attachments": [],
    "content_id": "fa748fae-3de4-4266-ae85-0797ada3f40c",
    "content_purpose_subgroup": "transactions",
    "content_purpose_supergroup": "services",
    "content_store_document_type": "transaction",
    "description": "Renew or tax your vehicle for the first time using a reminder letter, your log book or the green 'new keeper' slip - and how to tax if you do not have any documents",
    "document_type": "edition",
    "email_document_supertype": "other",
    "first_published_at": "2011-11-09T15:06:33Z",
    "format": "transaction",
    "government_document_supertype": "other",
    "indexable_content": "Tax your car, motorcycle or other vehicle using a reference number from:\n\na recent vehicle tax reminder or ‘last chance’ warning letter from DVLA\n\nyour vehicle log book (V5C) - it must be in your name\n\nthe green ‘new keeper’ slip from a log book if you’ve just bought it\n\nIf you do not have any of these documents, you’ll need to apply for a new log book. You can tax your vehicle at the same time.\n\nYou can pay by debit or credit card, or Direct Debit.\n\nYou must tax your vehicle even if you do not have to pay anything, for example if you’re exempt because you’re disabled.\n\nYou’ll need to meet all the legal obligations for drivers before you can drive.\n\nThis service is also available in Welsh (Cymraeg).",
    "is_historic": false,
    "is_political": false,
    "is_withdrawn": false,
    "link": "/vehicle-tax",
    "mainstream_browse_page_content_ids": [
      "c4cbf7d1-c44e-4f47-b2c8-380e0609f8b0"
    ],
    "mainstream_browse_pages": [
      "driving/vehicle-tax-mot-insurance"
    ],
    "organisation_content_ids": [
      "70580624-93b5-4aed-823b-76042486c769"
    ],
    "organisations": [
      "driver-and-vehicle-licensing-agency"
    ],
    "part_of_taxonomy_tree": [
      "f3bbdec2-0e62-4520-a7fd-6ffd5d36e03a",
      "a4038b29-b332-4f13-98b1-1c9709e216bc",
      "84a394d2-b388-4e4e-904e-136ca3f5dd7d",
      "dbbf7f4d-78aa-46ac-8e67-d937fe9a8c69",
      "1de432b7-2331-4450-9667-374d56e7f084"
    ],
    "people": [],
    "policy_groups": [],
    "popularity": 0.05263157894736842,
    "popularity_b": 327293,
    "primary_publishing_organisation": [
      "government-digital-service"
    ],
    "public_timestamp": "2017-12-07T12:54:39Z",
    "publishing_app": "publisher",
    "rendering_app": "frontend",
    "role_appointments": [],
    "roles": [],
    "taxons": [
      "1de432b7-2331-4450-9667-374d56e7f084"
    ],
    "title": "Tax your vehicle",
    "topical_events": [],
    "updated_at": "2025-03-17T17:52:47.687+00:00",
    "user_journey_document_supertype": "thing",
    "view_count": 1446391,
    "world_locations": [],
    "autocomplete": {
      "input": "Tax your vehicle",
      "weight": 327293
    }
  }
}
```

### `DELETE /content?link=/a-link`

Deletes the search result with the specified link.

Example response:

```
curl -XDELETE http://search-api.dev.gov.uk/content?link=/vehicle-tax
```

Will return 404 when the link is not found, 204 when it is deleted.
