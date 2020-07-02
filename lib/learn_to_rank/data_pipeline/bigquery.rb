require "google/cloud/bigquery"

module LearnToRank::DataPipeline
  module Bigquery
    def self.fetch(credentials)
      now = Time.now
      before = now - 90 * 24 * 60 * 60
      sql = "SELECT * FROM (
  SELECT
  searchTerm,
  link,
  ROUND(AVG(linkPosition)) AS avg_rank,
  COUNTIF(observationType = 'impression') AS views,
  COUNTIF(observationType = 'click') AS clicks
  FROM (
    SELECT
    CONCAT(fullVisitorId,'|',CAST(visitId AS STRING)) AS sessionId,
    customDimensions.value AS searchTerm,
    hits.hitNumber AS hitNumber, -- This is the hit number of the results page (for impressions) or the page itself (for clicks)
    product.v2ProductName AS link,
    product.productListPosition AS linkPosition,
    CASE
        WHEN product.isImpression = true and product.isClick IS NULL THEN 'impression'
        WHEN product.isClick = true and product.isImpression IS NULL THEN 'click'
        ELSE NULL
    END AS observationType
    FROM `govuk-bigquery-analytics.87773428.ga_sessions_*`
    CROSS JOIN UNNEST(hits) AS hits
    CROSS JOIN UNNEST(hits.product) AS product
    CROSS JOIN UNNEST(product.customDimensions) AS customDimensions
    WHERE product.productListName = 'Search'
    AND _TABLE_SUFFIX BETWEEN '#{before.strftime('%Y%m%d')}' AND '#{now.strftime('%Y%m%d')}'
    AND product.productListPosition <= 20
    AND customDimensions.index = 71 -- has search term
  ) AS action
  GROUP BY searchTerm, link, linkPosition
  ORDER BY views desc, searchTerm, linkPosition
) AS res
WHERE views > 10"

      bigquery = Google::Cloud::Bigquery.new(credentials: credentials)
      bigquery.query sql, standard_sql: true
    end
  end
end
