-- Inspect transaction IDs spanning users or reporting different revenues.
-- These conflicts require investigation before transaction-ID-only deduplication.

WITH purchases AS (
  SELECT
    user_pseudo_id,
    event_date,
    NULLIF(TRIM(ecommerce.transaction_id), '') AS transaction_id,
    ecommerce.purchase_revenue_in_usd AS revenue_usd
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
)

SELECT
  transaction_id,
  COUNT(*) AS purchase_event_count,
  COUNT(DISTINCT user_pseudo_id) AS user_count,
  MIN(revenue_usd) AS min_revenue_usd,
  MAX(revenue_usd) AS max_revenue_usd,
  MIN(event_date) AS first_observed_date,
  MAX(event_date) AS last_observed_date
FROM
  purchases
WHERE
  transaction_id IS NOT NULL
  AND LOWER(transaction_id) NOT IN ('(not set)', '<other>')
GROUP BY
  transaction_id
HAVING
  COUNT(DISTINCT user_pseudo_id) > 1
  OR MIN(revenue_usd) != MAX(revenue_usd)
ORDER BY
  user_count DESC,
  purchase_event_count DESC,
  transaction_id;
