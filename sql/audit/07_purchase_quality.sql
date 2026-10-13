-- Purchase data quality before transaction deduplication.
-- Distinct nonblank IDs include placeholders.
-- Raw purchase revenue is not deduplicated.

WITH purchases AS (
  SELECT
    NULLIF(TRIM(ecommerce.transaction_id), '') AS transaction_id,
    ecommerce.purchase_revenue_in_usd AS revenue_usd,
    ARRAY_LENGTH(items) AS item_count
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
)

SELECT
  COUNT(*) AS purchase_events,
  COUNTIF(transaction_id IS NULL) AS missing_transaction_id_events,
  COUNTIF(
    LOWER(transaction_id) IN ('(not set)', '<other>')
  ) AS placeholder_transaction_id_events,
  COUNT(DISTINCT transaction_id) AS distinct_nonblank_transaction_ids,
  COUNTIF(revenue_usd IS NULL) AS missing_revenue_events,
  COUNTIF(revenue_usd = 0) AS zero_revenue_events,
  COUNTIF(revenue_usd < 0) AS negative_revenue_events,
  COUNTIF(
    item_count IS NULL OR item_count = 0
  ) AS purchases_without_items,
  ROUND(SUM(revenue_usd), 2) AS raw_purchase_revenue_usd
FROM
  purchases;
