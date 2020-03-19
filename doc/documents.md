# Documents API (to be deprecated)

> **Note**: Once whitehall and Search Admin are using the [new indexing process](new-indexing-process.md),
the documents API will be removed and search API will consume only from the publishing API.

### `POST /:index/documents`

Insert or overwrite a document.

There must be a link attribute in the JSON body.

Any fields which are not part of the schema for the document type you are posting
will be silently ignored (see config/schema).

#### Example request and response

```json
{
    "organisations": [
      "department-for-transport",
      "driver-and-vehicle-licensing-agency"
    ],
    "public_timestamp": "2014-12-09T16:21:03+00:00",
    "description": "Renew or tax your vehicle for the first time, apply online, by phone or at the Post Office",
    "format": "transaction",
    "link": "/vehicle-tax",
    "mainstream_browse_pages": [
      "driving/car-tax-discs"
    ],
    "title": "Tax your vehicle",
    "_type": "edition",
    "_id": "/vehicle-tax",
    "specialist_sectors": []
}
```

```json
{
  "result": "OK"
}
```
