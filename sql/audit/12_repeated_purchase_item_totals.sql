-- Check item totals within repeated user-transaction pairs.
-- A difference above USD 0.01 is diagnostic, not a deletion rule.

WITH purchases AS (
  SELECT
    user_pseudo_id,
    NULLIF(TRIM(ecommerce.transaction_id), '') AS transaction_id,
    ecommerce.purchase_revenue_in_usd AS revenue_usd,
    TO_JSON_STRING(items) AS items_json,
    ARRAY_LENGTH(items) AS item_row_count,
    (
      SELECT SUM(item.quantity)
      FROM UNNEST(items) AS item
    ) AS item_quantity,
    (
      SELECT SUM(item.item_revenue_in_usd)
      FROM UNNEST(items) AS item
    ) AS item_revenue_usd,
    (
      SELECT COUNTIF(item.item_revenue_in_usd IS NULL)
      FROM UNNEST(items) AS item
    ) AS missing_item_revenue_rows
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
),

repeated_pairs AS (
  SELECT
    user_pseudo_id,
    transaction_id,
    COUNT(*) AS purchase_event_count,
    COUNT(DISTINCT items_json) AS item_payload_versions,
    COUNT(DISTINCT item_row_count) AS item_row_count_versions,
    COUNT(DISTINCT item_quantity) AS item_quantity_versions,
    COUNT(DISTINCT item_revenue_usd) AS item_revenue_versions,
    COUNTIF(
      item_revenue_usd IS NOT NULL
      AND ABS(item_revenue_usd - revenue_usd) > 0.01
    ) AS item_total_mismatch_events,
    COUNTIF(
      missing_item_revenue_rows > 0
      OR item_revenue_usd IS NULL
    ) AS incomplete_item_revenue_events
  FROM
    purchases
  WHERE
    transaction_id IS NOT NULL
    AND LOWER(transaction_id) NOT IN ('(not set)', '<other>')
  GROUP BY
    user_pseudo_id,
    transaction_id
  HAVING
    COUNT(*) > 1
)

SELECT
  COUNT(*) AS repeated_pairs,
  COUNTIF(item_payload_versions > 1) AS pairs_with_different_items,
  COUNTIF(item_row_count_versions > 1) AS pairs_with_different_item_counts,
  COUNTIF(item_quantity_versions > 1) AS pairs_with_different_quantities,
  COUNTIF(item_revenue_versions > 1) AS pairs_with_different_item_revenues,
  COUNTIF(
    item_total_mismatch_events > 0
  ) AS pairs_with_item_total_mismatch,
  COUNTIF(
    incomplete_item_revenue_events > 0
  ) AS pairs_with_incomplete_item_revenue
FROM
  repeated_pairs;
