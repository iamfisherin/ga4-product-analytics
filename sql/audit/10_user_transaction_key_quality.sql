-- Validate the sample-specific candidate order key:
-- (user_pseudo_id, transaction_id).

WITH purchases AS (
  SELECT
    user_pseudo_id,
    event_date,
    NULLIF(TRIM(ecommerce.transaction_id), '') AS transaction_id,
    ecommerce.purchase_revenue_in_usd AS revenue_usd,
    (
      SELECT param.value.int_value
      FROM UNNEST(event_params) AS param
      WHERE param.key = 'ga_session_id'
    ) AS ga_session_id
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
),

user_transaction_groups AS (
  SELECT
    user_pseudo_id,
    transaction_id,
    COUNT(*) AS purchase_event_count,
    COUNT(DISTINCT event_date) AS observed_dates,
    COUNT(DISTINCT ga_session_id) AS session_count,
    MIN(revenue_usd) AS min_revenue_usd,
    MAX(revenue_usd) AS max_revenue_usd
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
  SUM(purchase_event_count) AS purchase_events_with_usable_id,
  COUNT(*) AS user_transaction_pairs,
  COUNTIF(purchase_event_count > 1) AS repeated_pairs,
  SUM(purchase_event_count - 1) AS extra_events_for_repeated_pairs,
  MAX(purchase_event_count) AS max_events_per_pair,
  COUNTIF(
    min_revenue_usd != max_revenue_usd
  ) AS pairs_with_different_revenues,
  COUNTIF(observed_dates > 1) AS pairs_spanning_dates,
  COUNTIF(session_count > 1) AS pairs_spanning_sessions
FROM
  user_transaction_groups;
