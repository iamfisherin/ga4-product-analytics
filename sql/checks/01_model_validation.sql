-- Run after sql/models/00 through 04.
-- Expected values refer to the fixed sample window.

-- 1. Event staging validation
SELECT
  COUNT(*) AS event_count,
  COUNT(DISTINCT event_key) AS distinct_event_keys,
  COUNT(*) - COUNT(DISTINCT event_key) AS duplicate_event_key_rows,
  COUNT(DISTINCT session_key) AS observed_sessions,
  COUNT(DISTINCT user_pseudo_id) AS distinct_user_pseudo_ids,
  MIN(event_date) AS first_event_date,
  MAX(event_date) AS last_event_date,
  COUNTIF(ga_session_id IS NULL) AS missing_session_id_events,
  COUNTIF(event_name = 'purchase') AS purchase_events,
  ROUND(
    SUM(IF(event_name = 'purchase', purchase_revenue_usd, 0)),
    2
  ) AS raw_purchase_revenue_usd
FROM
  `ga4-product-analytics-511413.analytics.stg_events`;

-- 2. Session validation
SELECT
  COUNT(*) AS session_count,
  COUNT(DISTINCT session_key) AS distinct_session_keys,
  COUNT(*) - COUNT(DISTINCT session_key) AS duplicate_session_key_rows,
  SUM(event_count) AS total_events,
  COUNTIF(start_status = 'no_start') AS sessions_without_start,
  COUNTIF(start_status = 'one_start') AS sessions_with_one_start,
  COUNTIF(start_status = 'multiple_starts') AS sessions_with_multiple_starts,
  COUNTIF(spans_dates) AS sessions_spanning_dates,
  COUNTIF(has_purchase) AS purchasing_sessions,
  SUM(purchase_event_count) AS purchase_events
FROM
  `ga4-product-analytics-511413.analytics.mart_sessions`;

-- 3. Order validation
SELECT
  COUNT(*) AS identifiable_orders,
  COUNT(DISTINCT order_key) AS distinct_order_keys,
  COUNT(*) - COUNT(DISTINCT order_key) AS duplicate_order_key_rows,
  SUM(source_purchase_event_count) AS source_purchase_events,
  SUM(source_purchase_event_count - 1) AS extra_purchase_events,
  COUNTIF(has_repeated_purchase_events) AS orders_with_repeated_events,
  COUNTIF(has_item_payload_variation) AS orders_with_item_variation,
  COUNTIF(NOT revenue_is_consistent) AS orders_with_revenue_conflicts,
  ROUND(SUM(order_revenue_usd), 2) AS identifiable_order_revenue_usd
FROM
  `ga4-product-analytics-511413.analytics.mart_orders`;

-- 4. User validation
SELECT
  COUNT(*) AS user_count,
  COUNT(DISTINCT user_pseudo_id) AS distinct_user_ids,
  COUNT(*) - COUNT(DISTINCT user_pseudo_id) AS duplicate_user_rows,
  SUM(session_count) AS total_sessions,
  SUM(event_count) AS total_events,
  COUNTIF(has_purchase) AS purchasing_users,
  SUM(purchasing_session_count) AS purchasing_sessions,
  SUM(purchase_event_count) AS purchase_events,
  SUM(identifiable_order_count) AS identifiable_orders,
  ROUND(
    SUM(identifiable_order_revenue_usd), 2
  ) AS identifiable_order_revenue_usd
FROM
  `ga4-product-analytics-511413.analytics.mart_users`;
