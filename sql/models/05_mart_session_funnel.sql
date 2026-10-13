CREATE OR REPLACE TABLE `ga4-product-analytics-511413.analytics.mart_session_funnel`
CLUSTER BY device_category, country, user_pseudo_id
OPTIONS (description = 'Strictly increasing five-step session funnel; only sessions with session_start')
AS
WITH
funnel_events AS (
  SELECT session_key, event_name, event_timestamp_micros AS event_time
  FROM `ga4-product-analytics-511413.analytics.stg_events`
  WHERE event_name IN ('session_start', 'view_item', 'add_to_cart', 'begin_checkout', 'purchase')
),

starts AS (
  SELECT session_key, MIN(event_time) AS start_time
  FROM funnel_events WHERE event_name = 'session_start'
  GROUP BY session_key
),

views AS (
  SELECT p.session_key, p.start_time, MIN(e.event_time) AS view_time
  FROM starts AS p
  LEFT JOIN funnel_events AS e
    ON p.session_key = e.session_key
    AND e.event_name = 'view_item'
    AND e.event_time > p.start_time
  GROUP BY p.session_key, p.start_time
),

carts AS (
  SELECT p.session_key, p.start_time, p.view_time, MIN(e.event_time) AS cart_time
  FROM views AS p
  LEFT JOIN funnel_events AS e
    ON p.session_key = e.session_key
    AND e.event_name = 'add_to_cart'
    AND e.event_time > p.view_time
  GROUP BY p.session_key, p.start_time, p.view_time
),

checkouts AS (
  SELECT p.session_key, p.start_time, p.view_time, p.cart_time, MIN(e.event_time) AS checkout_time
  FROM carts AS p
  LEFT JOIN funnel_events AS e
    ON p.session_key = e.session_key
    AND e.event_name = 'begin_checkout'
    AND e.event_time > p.cart_time
  GROUP BY p.session_key, p.start_time, p.view_time, p.cart_time
),

purchases AS (
  SELECT p.session_key, p.start_time, p.view_time, p.cart_time, p.checkout_time, MIN(e.event_time) AS purchase_time
  FROM checkouts AS p
  LEFT JOIN funnel_events AS e
    ON p.session_key = e.session_key
    AND e.event_name = 'purchase'
    AND e.event_time > p.checkout_time
  GROUP BY p.session_key, p.start_time, p.view_time, p.cart_time, p.checkout_time
)
SELECT p.*, s.user_pseudo_id, s.session_observed_date,
  s.device_category, s.country, s.first_user_source, s.first_user_medium,
  s.start_status, s.has_purchase AS has_any_purchase,
  p.view_time IS NOT NULL AS reached_view_item,
  p.cart_time IS NOT NULL AS reached_add_to_cart,
  p.checkout_time IS NOT NULL AS reached_begin_checkout,
  p.purchase_time IS NOT NULL AS completed_strict_funnel,
  CASE
    WHEN p.purchase_time IS NOT NULL THEN 5
    WHEN p.checkout_time IS NOT NULL THEN 4
    WHEN p.cart_time IS NOT NULL THEN 3
    WHEN p.view_time IS NOT NULL THEN 2
    ELSE 1
  END AS furthest_stage
FROM purchases AS p
JOIN `ga4-product-analytics-511413.analytics.mart_sessions` AS s USING (session_key);
