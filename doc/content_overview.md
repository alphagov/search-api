# Content in the search index and where it comes from

This list documents the kinds of things included in Rummager's search indexes,
and the apps currently responsible for publishing them as of June 2017.

![Government content and HMRC manuals make up most of the content we index](rough_content_breakdown.png)

For a broader view of the content that is available, see [Document types on GOV.UK](https://docs.publishing.service.gov.uk/document-types.html).

## Publisher
Publishes "mainstream" content on GOV.UK - about 3000 pages which target common user needs. This is the kind of stuff you can reach from the homepage.

Implemented in [search_payload_presenter.rb](https://github.com/alphagov/publisher/blob/master/app/presenters/search_payload_presenter.rb).

 - 765 guides
 - 738 answers
 - 497 business supports (DEPRECATED)
 - 465 licences
 - 295 transactions
 - 127 local transactions
 - 29 simple smart answers
 - 20 places
 - 8 help pages


## Travel-advice-publisher
Publishes [foreign travel advice](https://www.gov.uk/foreign-travel-advice) on GOV.UK. There are 226 pages, but they have
a format of "custom application" in Rummager.

Implemented in [search_payload_presenter.rb](https://github.com/alphagov/travel-advice-publisher/blob/master/app/presenters/search_payload_presenter.rb).

## Collections-publisher
Publishes [/browse](https://www.gov.uk/browse) and [/topic](https://www.gov.uk/topic) pages on GOV.UK. There are around 500 collections.

Implemented in [tag_presenter.rb](https://github.com/alphagov/collections-publisher/blob/master/app/presenters/tag_presenter.rb).

- 397 specialist_sector
- 152 mainstream_browse_page

## Whitehall
This is what most publishers use to publish. Content appears on the ["inside government" part of GOV.UK](https://www.gov.uk/government/publications). There are 200,000 documents.

Implemented in [searchable.rb](https://github.com/alphagov/whitehall/blob/master/app/models/searchable.rb).

- 96460 publications
- 53678 news articles
- 11052 world location news articles
- 8112 speeches
- 4012 detailed guidance
- 3771 document collections
- 3766 consultations
- 3684 statistics announcements
- 2729 people
- 1579 case study
- 1109 corporate information pages
- 1017 organisations
- 677 policy groups
- 567 statistical data sets
- 501 fatality notices
- 455 worldwide organisations
- 318 ministers
- 234 world locations
- 63 topical events
- 47 “topics”
- 19 inside-government-links (DEPRECATED)
- 18 take parts
- 7 finders
- 5 operational fields

## Policy-publisher
Publishes [policies](https://www.gov.uk/government/policies) on GOV.UK. There are 224 policies

Implemented in [search_indexer.rb](https://github.com/alphagov/policy-publisher/blob/master/lib/policy_actions/search_indexer.rb).

## Manuals-publisher
Publishes manuals on GOV.UK, such as [the Highway Code](https://www.gov.uk/guidance/the-highway-code). There are 54 manuals, made up of 1277 manual sections.
Both manuals and manual sections show up as search results.

Implemented in [search_index_adapter.rb](https://github.com/alphagov/manuals-publisher/blob/master/app/adapters/search_index_adapter.rb).

## Specialist-publisher
Publishes specialist documents on GOV.UK, such as [CMA cases](https://www.gov.uk/cma-cases). There are 8000 documents.

Implemented in [search_presenter.rb](https://github.com/alphagov/specialist-publisher/blob/master/app/presenters/search_presenter.rb).

- 3363 Employment tribunal decisions
- 1747 CMA cases + 97 without publishing app set
- 1551 DFID research outputs + 28998 without publishing app set
- 335 Business finance support schemes
- 302 MAIB reports + 586 without publishing app set
- 243 Countryside stewardship grants + 2 without publishing app set
- 176 Employment appeal tribunal decisions
- 143 European structural investment funds + 473 without publishing app set
- 121 UTAAC decisions + 264 without publishing app set
- 113 Tax tribunal decisions + 595 without publishing app set
- 92 AAIB reports + 10013 without publishing app set
- 87 Medical safety alerts
- 81 Asylum support decisions
- 57 RAIB reports + 319 without publishing app set
- 21 Drug safety updates + 418 without publishing app set
- 21 Service standard reports + 47 without publishing app set
- 17 Finders
- 13 International development funds + 42 without publishing app set

## Service-manual-publisher
Publishes the GOV.UK [Service Manual](https://www.gov.uk/service-manual). There are 154 service manual guides
and 9 service manual topics.

Implemented in [guide_search_indexer.rb](https://github.com/alphagov/service-manual-publisher/blob/master/app/models/guide_search_indexer.rb), [topic_search_indexer.rb](https://github.com/alphagov/service-manual-publisher/blob/master/app/models/topic_search_indexer.rb), [service_standard_search_indexer.rb](https://github.com/alphagov/service-manual-publisher/blob/master/app/models/service_standard_search_indexer.rb), [homepage_search_indexer.rb](https://github.com/alphagov/service-manual-publisher/blob/master/app/models/homepage_search_indexer.rb).

## Contacts-admin
Publishes HMRC contact information on GOV.UK. There are 132 contacts.

Implemented in [contact_rummager_presenter](https://github.com/alphagov/contacts-admin/blob/master/app/presenters/contact_rummager_presenter.rb).

## Hmrc-manuals-api
Publishes HMRC manuals. There are 220 HMRC manuals, with 74953 HMRC manual sections.

Implemented in [rummager_manual.rb](https://github.com/alphagov/hmrc-manuals-api/blob/master/app/models/rummager_manual.rb), [rummager_section.rb](https://github.com/alphagov/hmrc-manuals-api/blob/master/app/models/rummager_section.rb).

## Search admin
Admin for GOV.UK search. Sends 506 "recommended links" to Rummager, so we can
show external links in search results.

Imeplemented in [elastic_search_recommended_link.rb](https://github.com/alphagov/search-admin/blob/master/app/models/elastic_search_recommended_link.rb).

## Static pages
Besides travel advice, the "custom application" format is used for [calendars](https://github.com/alphagov/calendars/tree/master/lib/data), some help pages,
and [calculators](https://github.com/alphagov/calculators), and the licence finder start page.

The bank holiday page has a [welsh translation](https://www.gov.uk/gwyliau-banc) that is indexed in search,
although it uses the same index as everything else, with english language stopwords and synonyms.


There are also some static pages using "edition" as a format:

- Publications page
- Find your local council
- Announcements page
- Organisations page
- Statistics page
- Ministers page
- How government works
- Get involved page
- Embassies
- 6 history pages
