SELECT
  COUNT(*) AS all_observed_sessions,
  COUNTIF(has_session_start) AS sessions_with_start,
  COUNTIF(has_purchase) AS all_purchasing_sessions,
  COUNTIF(has_session_start AND has_purchase) AS purchasing_sessions_with_start,
  COUNTIF(NOT has_session_start AND has_purchase) AS purchasing_sessions_without_start,
  ROUND(100.0 * SAFE_DIVIDE(COUNTIF(has_purchase), COUNT(*)), 2)
    AS purchase_presence_rate_all_sessions_pct,
  ROUND(100.0 * SAFE_DIVIDE(COUNTIF(has_session_start AND has_purchase), COUNTIF(has_session_start)), 2)
    AS purchase_presence_rate_started_sessions_pct
FROM `ga4-product-analytics-511413.analytics.mart_sessions`;
