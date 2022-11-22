# Relevancy

This document explains how relevancy ordering works when performing a
search.

## Contents

1. [What is relevancy?](#what-is-relevancy)
2. [What impacts relevancy?](#what-impacts-relevancy)
3. [What impacts document retrieval?](#what-impacts-document-retrieval)
   1. [Boosting](#boosting)
   2. [Best and worst bets](#best-and-worst-bets)
   3. [Stopwords](#stopwords)
   4. [Synonyms](#synonyms)
   5. [Categorisation of fields](#categorisation-of-fields)
   6. [Analyzers](#analyzers)
   7. [Excluded formats](#excluded-formats)
4. [Possible problems with queries and relevance](#possible-problems-with-queries-and-relevance)
5. [Finding underperforming queries](#finding-underperforming-queries)


## What is relevancy?

A list of documents returned by Search API will include an `es_score` and
a `combined_score` on every document.

```ruby
# Response for a search for 'Harry Potter'
[
  { title: "Harry Potter", combined_score: 3 },
  { title: "Harry Kane", combined_score: 2 },
  { title: "Ron Weasley", combined_score: 1 }
]
```

The `combined_score` is used for ranking results and represents how
relevant we think a result is to your query.

## What impacts relevancy?

Once Search API has [retrieved](#what-impacts-document-retrieval) the
top scoring documents from the search indexes, it ranks the results
in order of relevance using a pre-trained model.

See the [learning to rank](learning-to-rank.md) documentation for
more details.

## What impacts document retrieval?

Out of the box, Elasticsearch comes with a decent scoring algorithm.
They have a [guide on scoring relevancy][scoring] which is worth
reading.

We've done some work in Search API to [tune relevancy][relevancy],
overriding the default Elasticsearch behaviour, which we go into
below.

These following factors are combined into a single `es_score`. The
top scoring documents will be retrieved for ranking.

### Boosting

We don't only use the query relevancy score to rank documents, we
apply some additional boosting factors:

- **Popularity:** more visited documents are likely to be more useful
  to users.
- **Recency:** a more recently updated document is more likely to be
  useful than an older document.
- **Properties:** we have domain-specific knowledge about our
  content, and can make judgements on what sorts of content are more
  likely to be useful to the average user.

#### Popularity

This is updated nightly from recent Google Analytics data, gathered by
the [search-analytics][] application.

Here is the initial reasoning for the numbers ([6cbd84f][], May 2014):

> This field is populated from the page-traffic index, which in turn
> is populated from a dump file produced by the python scripts in the
> search-analytics repository.
>
> The popularity is currently defined here as 1.0 / the rank of the
> page in terms of traffic.  ie, Our highest traffic page gets 1.0,
> the next highest gets 0.5, the next highest gets 0.333.  This is a
> nice and stable measure.

If we want to boost the popularity of a query then we do so by 0.001
(`POPULARITY_OFFSET = 0.001` in [popularity.rb][]).  It is not clear
where this number came from.

We also boost using `boost_mode: :multiply` (multiply the `_score`
with the function result (default)).

We store page traffic data in the `page-traffic` index.  For each page
we store its rank relative to other pages on GOV.UK in the `rank_14`
field and its number of page views in the `vc_14` field.

#### Recency

This is an implementation of [this curve](https://solr.apache.org/guide/7_7/function-queries.html#recip-function),
and is applied to documents of the "announcement" type in the [booster.rb][]
file.  It serves to increase the score of new documents and decrease 
the score of old documents.

Only documents of `search_format_types` 'announcement' are affected by
recency boosting.

The curve was chosen so that it only applies the boost temporarily (2 
months moderate decay then a rapid decay after that).

#### Properties

This is defined by the [boosting.yml][] file, and is applied in the
[booster.rb][] file.

For example, if a document has `is_historic: true` we downrank it, so
it's less likely to appear at the top of search results.

It is unclear where the numbers came from.

### Best and worst bets

Some search queries have perfect answers.  For example, a search for
"HM Treasury" should have the HM Treasury organisation page as the top
result.

To handle these cases we have a concept called "best bets".

A "best bet" for a search query is a result that should be shoehorned
into the top of the results list for that query.  It's a way of
boosting that is a surefire route to having your document top the
results for a given query.

Best bets are managed with the [Search Admin][] application.

Example best bets:

```
Algeria: /foreign-travel-advice/algeria
Citizenship: /becoming-a-british-citizen
```

There's also a concept called "worst bets".  These are useful if our
search results are so bad that we have to manually downrank a result
for a given query.  For example, "vehicle" shouldn't result in
"unicycle" being the top result.

Best and worst bets are implemented in the [best_bets.rb][] file.

### Stopwords

Stopwords are words like "is", "and", "an", and "a".  They're words we
filter out when processing a search query, since they're so common
they're not useful.  They also enable Elasticsearch to maintain a
smaller index.

The stopwords themselves are provided by Elasticsearch.  There's
nothing in the Search API repo that looks at a list of omitted terms.
This is handled by the default [stop token filter][].

**History of stopwords**

There has been some talk of not including stopwords in the past
([0fe6e52][], May 2015) during this time a `no_stop` method was
implemented that seems to prevent stopwords from being used.  Again this
seems to be served by Elasticsearch because it's not defined in Search
API.

**Potential improvements to stopwords**

Given that we're taking a stock list of stopwords from Elasticsearch,
we may be missing out on a chance to edit them in a way that might be
more useful for users. Looking into what words to omit / not omit might
be a useful tuning exercise.

A search with stopwords is different to a search without stopwords:

- If you search Search API for stopwords then you get literally
  nothing: http://www.gov.uk/api/search.json?q=the+that+and+if

- If you search for nothing then you get the some of the more
  frequently clicked links: http://www.gov.uk/api/search.json?q=

### Synonyms

A synonym is a word or phrase that means exactly or nearly the same as
another word or phrase in the same language, for example shut is a
synonym of close.

We use synonyms to show relevant results related to "vehicle tax" regardless
of whether you searched for "car tax" or "auto tax".

Synonyms are defined in the [synonyms.yml][] file and are applied to
the Elasticsearch index configuration in the [schema_config.rb][]
file.

#### Grouping of synonyms

Each group of synonyms is written in the form:

```
foo, bar, baz => bat, qux, quux
```

This means that each of the (comma separated) terms on the left of the
`=>` map to each of the (comma separated) terms on the right.

For example:

```
leap, hop => jump
```

means "a search for 'leap' or 'hop' should return documents with
'jump' in them.

And:

```
run, speedwalk => sprint, gallop
```

means "a search for 'run' or 'speedwalk' should return documents with
'sprint' or 'gallop' in them."

It must be applied both at index time and at query time, to ensure that query
terms are mapped to the same single value that exists in the index.

### Filtering

Additional configuration is defined in the [elasticsearch_schema.yml][] and
[stems.yml][] files.  This configuration is merged with the JSON
configuration, and then passed to Elasticsearch directly.

[This blog post][synonyms-blog] suggests that as well as using
keywords, it can be useful to use "keepwords" to only filter the
phrases we want.

The post suggests to first generate [shingles][], followed by synonyms,
followed by [keepwords][].

In other words: generate candidate keyphrases by shingling, expand
them with synonyms, then cull out any non-synonyms with keepwords.

### Categorisation of fields

We use parts of a document differently when processing a search query.

We do some categorisation of document fields, to tell Elasticsearch what
we can use them for.

For example `date` is used for date fields which can be returned and used
for ordering, filtering and aggregating. This lets you filter e.g.
`filter_public_timestamp=from:2015-01-01`.

There are also fields like `acronym` which is categorised as a
`searchable_text` type that Elasticsearch looks at when you submit a keyword
search. So you can search for `MOD` and get a link to that organisation as
the top result.

These are configured in [`config/schema/field_types.json`](https://github.com/alphagov/search-api/blob/master/config/schema/field_types.json) and
[`config/schema/field_definitions.json`](https://github.com/alphagov/search-api/blob/master/config/schema/field_definitions.json).

### Analyzers

We have a number of custom analyzers that can be invoked at index time or when querying.

From the [Elasticsearch documentation][analyzer] on analyzers:

> The values of analyzed string fields are passed through an analyzer
> to convert the string into a stream of tokens or terms.  For
> instance, the string "The quick Brown Foxes." may, depending on
> which analyzer is used, be analyzed to the tokens: quick, brown,
> fox.  These are the actual terms that are indexed for the field,
> which makes it possible to search efficiently for individual words
> within big blobs of text.

This table describes what each of our analyzers do:

| Analyzer                 | Used by main query | Details                                                                 | Normalize quotes | Strip Quotes | Tokenize                 | Trim | Lowercase | Asciifolding | Old school synonyms | Remove stop words | Synonyms            | Mark protwords (not stemmed) | Stemmer override | Porter2 stemmer | Shingles      | ID codes analysis |
|--------------------------|--------------------|-------------------------------------------------------------------------|------------------|--------------|--------------------------|------|-----------|--------------|---------------------|-------------------|---------------------|------------------------------|------------------|-----------------|---------------|-------------------|
| `default`                | ✔                  | Main analyzer if synonyms are disabled                                  | ✔                | ✔            | standard                 | ✖    | ✔         |              | ✖                   | ✔                 | None                | None                         | ✔                | ✔               | ✖             | ✖                 |
| `searchable_text`        | ✖                  | New weighting query uses this for all_searchable_text and FIELD.no_stop | ✔                | ✔            | standard                 | ✖    | ✔         |              | ✖                   | ✖                 | None                | None                         | ✔                | ✔               | ✖             | ✖                 |
| `with_index_synonyms`    | ✖                  | New weighting query uses this for FIELD.synonym                         | ✔                | ✔            | standard                 | ✖    | ✔         |              | ✖                   | ✖                 | Index synonym list  | Synonyms                     | ✔                | ✔               | ✖             | ✖                 |
| `with_search_synonyms`   | ✖                  | New weighting query uses this at search time                            | ✔                | ✔            | standard                 | ✖    | ✔         |              | ✖                   | ✖                 | Search synonym list | Synonyms                     | ✔                | ✔               | ✖             | ✖                 |
| `exact_match`            | ✖                  | Used by best_bet_exact_match_text                                       | ✔                | ✖            | standard                 | ✔    | ✔         | ✖            | ✖                   | ✖                 | ✖                   | ✖                            | ✖                | ✖               | ✖             | ✖                 |
| `best_bet_stemmed_match` | ✖                  | Used for triggering best bets                                           | ✔                | ✔            | standard                 | ✖    | ✔         |              | ✖                   | ✖                 | ✖                   | ✖                            | ✔                | ✔               | ✖             | ✖                 |
| `spelling_analyzer`      | ✖                  | Used in spelling_text field                                             | ✔                | ✔            | standard                 | ✖    | ✔         |              | ✖                   | ✖                 | ✖                   | ✖                            | ✖                | ✖               | shingle       | ✖                 |
| `string_for_sorting`     | ✖                  | Used for storing a sortable subfield                                    | ✔                | ✔            | keyword                  | ✔    | ✔         | ✖            | ✖                   | ✖                 | ✖                   | ✖                            | ✖                | ✖               | ✖             | ✖                 |


Analyzers are used for different purposes, as the table describes. All of the
analyzers above are used for some purpose.

The main analyzer used at the moment is called `with_search_synonyms`.
This is the same as the `default` analyzer, except it also uses synonyms.


```yaml
# The default analyzer
with_search_synonyms:
  type: custom
  tokenizer: standard
  filter: [standard, asciifolding, lowercase, search_synonym, stop, stemmer_override, stemmer_english]
  char_filter: [normalize_quotes, strip_quotes]
```

These are the steps, ignoring asciifolding, which have been added:

1. Normalise and strip quotes

  The character filters ensure that words with curly apostrophes are normalised
  and in some cases removed, for consistent behaviour when searching with
  quotes.

  ```ruby
    "It's A Small’s World" => ["it", "small", "world"],
    "H'lo ’Hallo" => ["h'lo", "h'lo hallo", "hallo"]
  ```

   ```
   normalize_quotes:
     type: "mapping"
     mappings:
        - "\u0091=>\u0027"
        - "\u0092=>\u0027"
        - "\u2018=>\u0027"
        - "\u2019=>\u0027"
        - "\uFF07=>\u0027"

   strip_quotes:
     type: "pattern_replace"
     pattern: "\'"
     replacement: ""
   ```

2. Split into tokens (tokenizer)

   We use the default Elasticsearch tokeniser (`tokenizer: standard`).

   The standard tokeniser uses the unicode text segmentation algorithm.
   https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-standard-tokenizer.html

3. Lowercase everything (filter)

   https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-lowercase-tokenfilter.html

4. Remove stopwords (filter)

   https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-stop-tokenfilter.html

   Removes words in the english stopword list

5. Apply our custom stemmer override to each token (filter)

   Customises stemming using this list
   https://github.com/alphagov/search-api/blob/master/config/schema/stems.yml

6. Apply the english Stemmer to each token (filter)

   The [Porter2 stemming algorithm][] for english text, an improvement
   to the Porter algorithm.
   https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-stemmer-tokenfilter.html


### Excluded formats

There are some document formats that are not included in search results.
These include smart answers, calculators, licence finders.

We also exclude some paths, such as `/random`, `/homepage`, and `/humans.txt`.

These no-indexed paths and formats are defined in [`config/govuk_index/migrated_formats.yaml`](https://github.com/alphagov/search-api/blob/master/config/govuk_index/migrated_formats.yaml).

### Debugging es_score

If you want to understand why a result has a given `es_score`, you can
use the Elasticsearch [Explain API][explain].  This is exposed by the
Search API.

Please note that `es_score` is just one feature used by the reranking
model; we don't rank results using `es_score` alone.

You can see the reasons behind an `es_score` by including the
`debug=explain` query parameter in your query.  This will add an
`_explanation` field to every result, similar to a SQL-like `EXPLAIN`.

For example, see the explanation produced by [searching for "harry
potter"][explain-example].  This shows an example of stemming, where
"harry" becomes "harri".  This is due to the rule "replace suffix 'y'
or 'Y' by 'i' if preceded by a non-vowel which is not the first letter
of the word".  You can also see that text similarity scoring ([BM25][]
in Elasticsearch 6) works by considering both term frequency and
document frequency.

You can see the query Search API sends to Elasticsearch with the
`debug=show_query` parameter.  Debug parameters can be combined, like
`debug=show_query,explain`.  The debug output is verbose, so sometimes
restricting to only a handful of results, with `count=0` or `count=1`,
is useful.

## Possible problems with queries and relevance

### The way we handle longer search terms is broken

We use [phrase queries][] to take phrases into account in search queries.

We're not using the _[slop][]_ parameter, so the phrase component will
only work where the query uses the exact same phrasing. It's not clear
whether this would be useful, except maybe for names of services/forms/departments.

The `slop` parameter tells the `match_phrase` query how far apart terms are
allowed to be while still considering the document a match. By _how far
apart_ we mean _how many times do you need to move a term in order to make
the query and document match?_

Explanation from the Lucene documentation:

> Sets the number of other words permitted between words in query phrase.
> If zero, then this is an exact phrase search.

> The slop is in fact an edit-distance, where the units correspond to moves
> of terms in the query phrase out of position. For example, to switch the
> order of two words requires two moves (the first move places the words
> atop one another), so to permit re-orderings of phrases, the slop must
> be at least two.

> More exact matches are scored higher than sloppier matches, thus
> search results are sorted by exactness.

Essentially, with a `slop` value of 1, a query for 'harry potter' would
return documents with the phrase 'potter harry' in them.

Although all words need to be present in phrase matching, even when using
slop, the words don’t necessarily need to be in the same sequence in order
to match. With a high enough slop value, words can be arranged in any order.

[Shingles][shingles] are another way to take phrases into account,
which allow matching n-grams.  This was implemented in the past, but
was broken ([6ece793][], May 2015) and the fixed implementation never
went live ([806a68c][], Dec 2017).

### There is no boosting of individual field matches

We treat a match in title, description, acronym and indexable content
the same, but these are different things.  A user might expect title
and description matches to be much more important than body content.

We're using field-specific boosts (applied in the [core_query.rb][]
file) when the query is a quoted phrase, but not for normal searches.

```ruby
PHRASE_MATCH_TITLE_BOOST = 5
PHRASE_MATCH_ACRONYM_BOOST = 5
PHRASE_MATCH_DESCRIPTION_BOOST = 2
PHRASE_MATCH_INDEXABLE_CONTENT_BOOST = 1
```

### Popularity is the main proxy for "good"

Popularity is one of the biggest factors influencing the weighting.
It's based on the overall page views, so there's a positive feedback
loop where something gets popular, which makes it more visible, which
makes it even more popular.

In the past this has caused problems when we know content is better
but something else still gets high traffic ([03c4bfa][], May 2015).

If we had other signals of content quality we might be able to reduce our
dependence on the page views.

### Finding underperforming queries

1. Go to the [datastudio report][]

The report does not automatically update, so it will display only the data for the dates displayed.

To get new data, rerun the BigQuery queries.

2. Apply the following filters:

* `click_count >= 100`
* `median_position >=4`

Underperforming queries are ones with a significant click count and a highish median, i.e. around 4 and above.

![datastudio](images/datastudio-dash.png)

3. Visit the Google Analytics dashboard an underperforming query

Once you have identified an underperforming query, head over to the Google Analytics (GA) dashboard to see the clickthrough rates and positions of the search results for that query.

e.g. [GA dashboard][] for the term "utr".

Use the clickthrough rate of each search result relative to its position to inform your hypotheses.


[03c4bfa]: https://github.com/alphagov/search-api/commit/03c4bfa0a1a816a57d38b71ac5cb22c3a107c275
[0fe6e52]: https://github.com/alphagov/search-api/commit/0fe6e526c78e8b115371855a91d4b39ccb22098a
[6cbd84f]: https://github.com/alphagov/search-api/commit/6cbd84f36ff70ce1be6a368e807c72ba09c74f23
[6ece793]: https://github.com/alphagov/search-api/commit/6ece793190932fee31be5437c4c56773dc358ff6
[806a68c]: https://github.com/alphagov/search-api/commit/806a68cb11f926c328bf360171c754ed6fca06ac

[best_bets.rb]: https://github.com/alphagov/search-api/blob/master/lib/search/query_components/best_bets.rb
[booster.rb]: https://github.com/alphagov/search-api/blob/master/lib/search/query_components/booster.rb
[boosting.yml]: https://github.com/alphagov/search-api/blob/master/config/query/boosting.yml
[core_query.rb]: https://github.com/alphagov/search-api/blob/master/lib/search/query_components/core_query.rb
[elasticsearch_schema.yml]: https://github.com/alphagov/search-api/blob/master/config/schema/elasticsearch_schema.yml
[popularity.rb]: https://github.com/alphagov/search-api/blob/master/lib/search/query_components/popularity.rb
[schema_config.rb]: https://github.com/alphagov/search-api/blob/master/lib/schema/schema_config.rb
[stems.yml]: https://github.com/alphagov/search-api/blob/master/config/schema/stems.yml
[synonyms.yml]: https://github.com/alphagov/search-api/blob/master/config/schema/synonyms.yml

[BM25]: https://www.elastic.co/guide/en/elasticsearch/reference/current/index-modules-similarity.html#bm25
[Porter2 stemming algorithm]: http://snowball.tartarus.org/algorithms/english/stemmer.html
[Search Admin]: https://github.com/alphagov/search-admin
[analyzer]: https://www.elastic.co/guide/en/elasticsearch/reference/current/analyzer.html
[explain-example]: https://www.gov.uk/api/search.json?debug=explain&q=harry%20potter
[explain]: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-explain.html
[phrase queries]: https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-query-phrase.html
[relevancy]: https://www.elastic.co/guide/en/elasticsearch/guide/master/relevance-conclusion.html
[scoring]: https://www.elastic.co/guide/en/elasticsearch/guide/master/scoring-theory.html
[search-analytics]: https://github.com/alphagov/search-analytics
[shingles]: https://www.elastic.co/blog/searching-with-shingles
[slop]: https://www.elastic.co/guide/en/elasticsearch/guide/current/slop.html
[stop token filter]: https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-stop-tokenfilter.html
[synonyms-blog]: https://opensourceconnections.com/blog/2016/12/02/solr-elasticsearch-synonyms-better-patterns-keyphrases/
[this curve]: http://www.wolframalpha.com/share/clip?f=d41d8cd98f00b204e9800998ecf8427e5qr62u0si
[keepwords]: https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-keep-words-tokenfilter.html
[datastudio report]: https://datastudio.google.com/u/0/reporting/1-QjJDH5YkBWhF9qb-WEOuGuGIgNJExds/page/Zaus
[GA dashboard]: https://analytics.google.com/analytics/web/#/report/conversions-ecommerce-product-list-performance/a26179049w50705554p53872948/_u.date00=20191016&_u.date01=20191023&explorer-table.plotKeys=%5B%5D&explorer-table.rowCount=50&explorer-table.secSegmentId=analytics.customDimension71&explorer-table.advFilter=%5B%5B0,"analytics.productListPosition","RE","%5E%5B0-9%5D%7B1,1%7D$",0%5D,%5B0,"analytics.customDimension71","EQ","utr",0%5D%5D&_r.drilldown=analytics.productListName:Search&explorer-table-dataTable.sortColumnName=analytics.productListCTR&explorer-table-dataTable.sortDescending=true&explorer-segmentExplorer.segmentId=analytics.productListPosition/
