# How Search API Populates Popularity Fields

The GOV.UK Search API maintains several fields related to document popularity. These fields are populated using two scheduled rake tasks:

- **`page_traffic`** — fetches and processes traffic data from Google Analytics 4 (GA4), storing the results in the _page_traffic_ Elasticsearch index.
- **`update_popularity`** — reads the processed data from the _page_traffic_ index and updates the popularity-related fields on documents in the main search index.
---

### Collecting and preparing traffic data

The `page_traffic` task retrieves page performance data from GA4 and stores a processed version in the _page_traffic_ Elasticsearch index. The processing consists of the following steps:

#### Step 1 — filter out unwanted pages

Exclude pages that should not contribute to popularity calculations:

- External (non-GOV.UK) URLs
- Smart Answers
- “Page not found” pages

#### Step 2 — group by base path

Combine pages with the same base path (ignoring query parameters) and sum their pageviews.

#### Step 3 — rank and index

Sort the grouped set in descending order by total pageviews. Each entry is written to the _page_traffic_ index with these fields:

| Field | Description                                                 |
|-------|-------------------------------------------------------------|
| **rank_14** | The document’s zero-based rank in the sorted list           |
| **vc_14** | Absolute number of pageviews for the grouped base path      |
| **vf_14** | Proportion of total pageviews (pageviews ÷ total pageviews) |

---

### Applying popularity to search documents

The `update_popularity` task reads the entries from the _page_traffic_ index and updates documents in the main search index by setting fields derived from the traffic data. The primary fields populated are:

| Field | Description                     |
|-------|---------------------------------|
| **popularity** | 1 / (rank_14 + _offset_)        |
| **popularity_b** | (size_of_ranked_list) - rank_14 |
| **view_count** | vc_14                           |

The _offset_ used in the popularity calculation is defined in the `/elasticsearch.yml` file as _popularity_rank_offset_.
