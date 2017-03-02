# Searching using the subject taxonomy

Content can be tagged to any number of topics within the [subject taxonomy](https://insidegovuk.blog.gov.uk/2015/11/02/developing-a-subject-based-taxonomy-for-gov-uk/).

Documents have two taxonomy fields:
- `taxons` contains the content ids of each topic the document is tagged to.
- `part_of_taxonomy_tree` contains the content ids of each topic and the broader
   topics they descend from.

These can be returned with the `fields` parameter:

https://www.gov.uk/api/search.json?filter_part_of_taxonomy_tree=c58fdadd-7743-46d6-9629-90bb3ccc4ef0&fields=title,taxons,part_of_taxonomy_tree

## Get topics within a taxonomy

Rummager doesn't currently contain the topics themselves, but you can query
the content store API to get the full taxonomy, with titles and content IDs.

For example, for https://www.gov.uk/education, you can request
https://www.gov.uk/api/content/education which will show the full taxonomy
as part of `links`.

## Find content directly tagged to a topic

Filter on the `taxons` field to get content tagged to a topic.

https://www.gov.uk/api/search.json?filter_taxons=940e7a57-171a-4dad-b6eb-e2a5a87c9cec

## Find content tagged to any taxon within a taxonomy

Filter on the `part_of_taxonomy_tree` field to get content tagged to any topic
within a taxonomy.

https://www.gov.uk/api/search.json?filter_part_of_taxonomy_tree=c58fdadd-7743-46d6-9629-90bb3ccc4ef0

## Summarising taxons

Use the `taxons` field as a facet to see the number of documents in each topic.

https://www.gov.uk/api/search.json?filter_part_of_taxonomy_tree=c58fdadd-7743-46d6-9629-90bb3ccc4ef0&facet_taxons=1000&count=0
