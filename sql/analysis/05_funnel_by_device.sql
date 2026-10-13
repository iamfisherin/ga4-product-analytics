WITH segment_counts AS (
  SELECT COALESCE(NULLIF(TRIM(device_category), ''), 'unknown') AS device_category,
    COUNT(*) AS started_sessions,
    COUNTIF(reached_view_item) AS view_sessions,
    COUNTIF(reached_add_to_cart) AS cart_sessions,
    COUNTIF(reached_begin_checkout) AS checkout_sessions,
    COUNTIF(completed_strict_funnel) AS strict_purchase_sessions,
    COUNTIF(has_any_purchase) AS any_purchase_sessions
  FROM `ga4-product-analytics-511413.analytics.mart_session_funnel`
  GROUP BY 1
)
SELECT *,
  ROUND(100.0 * SAFE_DIVIDE(view_sessions, started_sessions), 2) AS start_to_view_pct,
  ROUND(100.0 * SAFE_DIVIDE(cart_sessions, view_sessions), 2) AS view_to_cart_pct,
  ROUND(100.0 * SAFE_DIVIDE(checkout_sessions, cart_sessions), 2) AS cart_to_checkout_pct,
  ROUND(100.0 * SAFE_DIVIDE(strict_purchase_sessions, checkout_sessions), 2) AS checkout_to_purchase_pct,
  ROUND(100.0 * SAFE_DIVIDE(strict_purchase_sessions, started_sessions), 2) AS strict_funnel_completion_pct,
  ROUND(100.0 * SAFE_DIVIDE(any_purchase_sessions, started_sessions), 2) AS purchase_presence_pct
FROM segment_counts ORDER BY started_sessions DESC;
