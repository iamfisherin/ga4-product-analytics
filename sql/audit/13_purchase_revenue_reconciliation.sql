-- Reconcile identifiable order revenue and unresolved-ID event revenue.
-- The raw baseline overlaps the other rows; do not sum all rows.
-- Revenue equality within each user-transaction pair was audited separately.

WITH purchases AS (
  SELECT
    user_pseudo_id,
    NULLIF(TRIM(ecommerce.transaction_id), '') AS transaction_id,
    ecommerce.purchase_revenue_in_usd AS revenue_usd
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
),

identifiable_orders AS (
  SELECT
    user_pseudo_id,
    transaction_id,
    COUNT(*) AS source_purchase_events,
    MIN(revenue_usd) AS order_revenue_usd
  FROM
    purchases
  WHERE
    transaction_id IS NOT NULL
    AND LOWER(transaction_id) NOT IN ('(not set)', '<other>')
  GROUP BY
    user_pseudo_id,
    transaction_id
)

SELECT
  'identifiable_orders_deduplicated' AS metric_scope,
  'user_transaction_pair' AS counting_unit,
  COUNT(*) AS record_count,
  SUM(source_purchase_events) AS source_purchase_events,
  ROUND(SUM(order_revenue_usd), 2) AS revenue_usd
FROM identifiable_orders

UNION ALL

SELECT
  'missing_transaction_id',
  'purchase_event',
  COUNT(*),
  COUNT(*),
  ROUND(SUM(revenue_usd), 2)
FROM purchases
WHERE transaction_id IS NULL

UNION ALL

SELECT
  'placeholder_transaction_id',
  'purchase_event',
  COUNT(*),
  COUNT(*),
  ROUND(SUM(revenue_usd), 2)
FROM purchases
WHERE LOWER(transaction_id) IN ('(not set)', '<other>')

UNION ALL

SELECT
  'all_purchase_events_raw',
  'purchase_event',
  COUNT(*),
  COUNT(*),
  ROUND(SUM(revenue_usd), 2)
FROM purchases;
