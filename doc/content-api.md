# Content API

### `GET /content/?link=/a-link`

Returns information about the search result with the specified link.

### Example response

```
curl -XGET http://search-api.dev.gov.uk/content?link=/vehicle-tax
```

Currently returns a hash with one element: `raw_source`, which contains the raw elasticsearch document.

```json
{  
   "raw_source":{  
      "organisations":[  
         "department-for-transport",
         "driver-and-vehicle-licensing-agency"
      ],
      "popularity":0.08333333333333333,
      "public_timestamp":"2014-12-09T16:21:03+00:00",
      "format":"transaction",
      "title":"Renew vehicle tax",
      "description":"Renew your vehicle tax, apply online, by phone or at the Post Office",
      "link":"/vehicle-tax",
      "indexable_content":"[..snip..]",
      "mainstream_browse_pages":[  
         "driving/car-tax-discs"
      ],
      "_type":"edition",
      "_id":"/vehicle-tax"
   }
}
```

### `DELETE /content/?link=/a-link`

Deletes the search result with the specified link.


## Example response

```
curl -XDELETE http://search-api.dev.gov.uk/content?link=/vehicle-tax
```

Will return 404 when the link is not found, 204 when it is deleted.
