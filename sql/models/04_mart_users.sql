-- One row per anonymous user identifier observed in the sample window.
-- Aggregate sessions and orders separately before joining.
-- First observed date is not a registration date.

CREATE OR REPLACE TABLE
  `ga4-product-analytics-511413.analytics.mart_users`
CLUSTER BY user_pseudo_id
OPTIONS (
  description = 'One row per anonymous user identifier observed in the sample window; not lifetime customer metrics'
)
AS

WITH user_sessions AS (
  SELECT
    user_pseudo_id,
    MIN(session_observed_date) AS first_observed_date,
    MAX(session_observed_date) AS last_observed_session_date,
    MIN(first_observed_at) AS first_observed_at,
    MAX(last_observed_at) AS last_observed_at,

    COUNT(*) AS session_count,
    SUM(event_count) AS event_count,
    COUNTIF(has_purchase) AS purchasing_session_count,
    SUM(purchase_event_count) AS purchase_event_count,

    ARRAY_AGG(
      STRUCT(
        device_category AS first_observed_device_category,
        country AS first_observed_country,
        first_user_source AS first_user_source,
        first_user_medium AS first_user_medium,
        first_user_campaign AS first_user_campaign
      )
      ORDER BY first_observed_at, session_key
      LIMIT 1
    )[OFFSET(0)] AS first_session_dimensions

  FROM
    `ga4-product-analytics-511413.analytics.mart_sessions`
  GROUP BY
    user_pseudo_id
),

user_orders AS (
  SELECT
    user_pseudo_id,
    COUNT(*) AS identifiable_order_count,
    SUM(order_revenue_usd) AS identifiable_order_revenue_usd,
    MIN(order_date) AS first_identifiable_order_date,
    MAX(order_date) AS last_identifiable_order_date
  FROM
    `ga4-product-analytics-511413.analytics.mart_orders`
  GROUP BY
    user_pseudo_id
)

SELECT
  s.* EXCEPT(first_session_dimensions),
  s.first_session_dimensions.*,

  s.purchase_event_count > 0 AS has_purchase,
  COALESCE(o.identifiable_order_count, 0) AS identifiable_order_count,
  COALESCE(
    o.identifiable_order_revenue_usd, 0
  ) AS identifiable_order_revenue_usd,
  o.first_identifiable_order_date,
  o.last_identifiable_order_date

FROM
  user_sessions AS s
LEFT JOIN
  user_orders AS o
USING (user_pseudo_id);
