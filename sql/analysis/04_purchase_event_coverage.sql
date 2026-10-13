-- Mutually exclusive categories, assigned by first missing intermediate stage.
WITH classified_sessions AS (
  SELECT session_key,
    CASE
      WHEN NOT has_view_item THEN '1_missing_view_item'
      WHEN NOT has_add_to_cart THEN '2_has_view_missing_add_to_cart'
      WHEN NOT has_begin_checkout THEN '3_has_view_and_cart_missing_checkout'
      ELSE '4_all_five_events_present'
    END AS event_coverage_group
  FROM `ga4-product-analytics-511413.analytics.mart_sessions`
  WHERE has_session_start AND has_purchase
)
SELECT event_coverage_group, COUNT(*) AS purchasing_sessions,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_started_purchasing_sessions
FROM classified_sessions
GROUP BY event_coverage_group ORDER BY event_coverage_group;
