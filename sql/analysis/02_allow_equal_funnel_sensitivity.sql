-- Sensitivity only: equal timestamps do not prove event order.
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
    AND e.event_time >= p.start_time
  GROUP BY p.session_key, p.start_time
),

carts AS (
  SELECT p.session_key, p.start_time, p.view_time, MIN(e.event_time) AS cart_time
  FROM views AS p
  LEFT JOIN funnel_events AS e
    ON p.session_key = e.session_key
    AND e.event_name = 'add_to_cart'
    AND e.event_time >= p.view_time
  GROUP BY p.session_key, p.start_time, p.view_time
),

checkouts AS (
  SELECT p.session_key, p.start_time, p.view_time, p.cart_time, MIN(e.event_time) AS checkout_time
  FROM carts AS p
  LEFT JOIN funnel_events AS e
    ON p.session_key = e.session_key
    AND e.event_name = 'begin_checkout'
    AND e.event_time >= p.cart_time
  GROUP BY p.session_key, p.start_time, p.view_time, p.cart_time
),

purchases AS (
  SELECT p.session_key, p.start_time, p.view_time, p.cart_time, p.checkout_time, MIN(e.event_time) AS purchase_time
  FROM checkouts AS p
  LEFT JOIN funnel_events AS e
    ON p.session_key = e.session_key
    AND e.event_name = 'purchase'
    AND e.event_time >= p.checkout_time
  GROUP BY p.session_key, p.start_time, p.view_time, p.cart_time, p.checkout_time
),

stage_counts AS (
  SELECT 1 AS stage_number, 'session_start' AS stage, COUNT(*) AS sessions FROM purchases
  UNION ALL SELECT 2, 'view_item', COUNTIF(view_time IS NOT NULL) FROM purchases
  UNION ALL SELECT 3, 'add_to_cart', COUNTIF(cart_time IS NOT NULL) FROM purchases
  UNION ALL SELECT 4, 'begin_checkout', COUNTIF(checkout_time IS NOT NULL) FROM purchases
  UNION ALL SELECT 5, 'purchase', COUNTIF(purchase_time IS NOT NULL) FROM purchases
)
SELECT stage_number, stage, sessions,
  ROUND(100.0 * SAFE_DIVIDE(sessions, LAG(sessions) OVER (ORDER BY stage_number)), 2)
    AS conversion_from_previous_pct,
  ROUND(100.0 * SAFE_DIVIDE(sessions, FIRST_VALUE(sessions) OVER (ORDER BY stage_number)), 2)
    AS conversion_from_start_pct
FROM stage_counts ORDER BY stage_number;
