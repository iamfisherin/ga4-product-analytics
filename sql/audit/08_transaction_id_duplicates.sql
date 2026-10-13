-- Audit usable transaction IDs before choosing an order key.
-- Exclude null, blank, and known placeholder IDs.

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

transaction_groups AS (
  SELECT
    transaction_id,
    COUNT(*) AS purchase_event_count,
    COUNT(DISTINCT user_pseudo_id) AS user_count,
    MIN(revenue_usd) AS min_revenue_usd,
    MAX(revenue_usd) AS max_revenue_usd,
    SUM(revenue_usd) AS raw_revenue_usd
  FROM
    purchases
  WHERE
    transaction_id IS NOT NULL
    AND LOWER(transaction_id) NOT IN ('(not set)', '<other>')
  GROUP BY
    transaction_id
)

SELECT
  SUM(purchase_event_count) AS purchase_events_with_usable_id,
  COUNT(*) AS distinct_usable_transaction_ids,
  COUNTIF(purchase_event_count > 1) AS repeated_transaction_ids,
  SUM(purchase_event_count - 1) AS extra_events_for_repeated_ids,
  MAX(purchase_event_count) AS max_events_per_transaction_id,
  COUNTIF(user_count > 1) AS transaction_ids_across_users,
  COUNTIF(
    min_revenue_usd != max_revenue_usd
  ) AS transaction_ids_with_different_revenues,
  ROUND(SUM(raw_revenue_usd), 2) AS raw_revenue_with_usable_id_usd
FROM
  transaction_groups;
