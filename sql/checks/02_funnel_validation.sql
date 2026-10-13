SELECT
  COUNT(*) AS sessions_with_start,
  COUNT(*) - COUNT(DISTINCT session_key) AS duplicate_session_rows,
  COUNTIF(reached_view_item) AS reached_view_sessions,
  COUNTIF(reached_add_to_cart) AS reached_cart_sessions,
  COUNTIF(reached_begin_checkout) AS reached_checkout_sessions,
  COUNTIF(completed_strict_funnel) AS completed_funnel_sessions,
  COUNTIF(has_any_purchase) AS purchasing_sessions,
  COUNTIF(
    (reached_add_to_cart AND NOT reached_view_item)
    OR (reached_begin_checkout AND NOT reached_add_to_cart)
    OR (completed_strict_funnel AND NOT reached_begin_checkout)
    OR (completed_strict_funnel AND NOT has_any_purchase)
  ) AS invalid_stage_flag_rows,
  COUNTIF(
    (view_time IS NOT NULL AND view_time <= start_time)
    OR (cart_time IS NOT NULL AND cart_time <= view_time)
    OR (checkout_time IS NOT NULL AND checkout_time <= cart_time)
    OR (purchase_time IS NOT NULL AND purchase_time <= checkout_time)
  ) AS invalid_time_order_rows
FROM `ga4-product-analytics-511413.analytics.mart_session_funnel`;
