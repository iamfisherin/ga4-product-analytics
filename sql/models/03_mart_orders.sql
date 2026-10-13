-- Sample-specific order proxy: (user_pseudo_id, transaction_id).
-- Exclude unresolved transaction IDs.
-- Preserve item variation flags; representative items are not verified baskets.

CREATE OR REPLACE TABLE
  `ga4-product-analytics-511413.analytics.mart_orders`
CLUSTER BY user_pseudo_id, session_key
OPTIONS (
  description = 'Sample-specific identifiable order proxies; unresolved transaction IDs excluded; item variation flagged'
)
AS

WITH ranked_purchases AS (
  SELECT
    *,

    ROW_NUMBER() OVER (
      PARTITION BY user_pseudo_id, transaction_id
      ORDER BY event_timestamp_micros, event_key
    ) AS purchase_rank,

    COUNT(*) OVER (
      PARTITION BY user_pseudo_id, transaction_id
    ) AS source_purchase_event_count,

    COUNT(DISTINCT TO_JSON_STRING(items)) OVER (
      PARTITION BY user_pseudo_id, transaction_id
    ) AS item_payload_versions,

    MIN(purchase_revenue_usd) OVER (
      PARTITION BY user_pseudo_id, transaction_id
    ) AS min_order_revenue_usd,

    MAX(purchase_revenue_usd) OVER (
      PARTITION BY user_pseudo_id, transaction_id
    ) AS max_order_revenue_usd

  FROM
    `ga4-product-analytics-511413.analytics.stg_events`
  WHERE
    event_name = 'purchase'
    AND transaction_id IS NOT NULL
    AND LOWER(transaction_id) NOT IN ('(not set)', '<other>')
)

SELECT
  TO_HEX(
    SHA256(
      TO_JSON_STRING(
        STRUCT(
          user_pseudo_id AS user_pseudo_id,
          transaction_id AS transaction_id
        )
      )
    )
  ) AS order_key,

  user_pseudo_id,
  transaction_id,
  session_key,
  ga_session_id,
  event_key AS representative_event_key,
  event_date AS order_date,
  event_timestamp_utc AS first_purchase_at,
  purchase_revenue_usd AS order_revenue_usd,

  device_category,
  country,
  region,
  city,
  first_user_source,
  first_user_medium,
  first_user_campaign,

  source_purchase_event_count,
  source_purchase_event_count > 1 AS has_repeated_purchase_events,
  item_payload_versions,
  item_payload_versions > 1 AS has_item_payload_variation,
  min_order_revenue_usd = max_order_revenue_usd AS revenue_is_consistent,
  items AS representative_items

FROM
  ranked_purchases
WHERE
  purchase_rank = 1;
