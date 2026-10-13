-- All observed sessions; revenue covers identifiable order proxies only.
-- Aggregate orders by session before joining to avoid fan-out.
WITH session_orders AS (
  SELECT session_key, COUNT(*) AS identifiable_orders,
    SUM(order_revenue_usd) AS identifiable_revenue_usd
  FROM `ga4-product-analytics-511413.analytics.mart_orders` GROUP BY session_key
),
country_metrics AS (
  SELECT COALESCE(NULLIF(TRIM(s.country), ''), 'unknown') AS country,
    COUNT(*) AS observed_sessions,
    COUNT(DISTINCT s.user_pseudo_id) AS distinct_user_ids,
    COUNTIF(s.has_purchase) AS purchasing_sessions,
    SUM(COALESCE(o.identifiable_orders, 0)) AS identifiable_orders,
    SUM(COALESCE(o.identifiable_revenue_usd, 0)) AS identifiable_revenue_usd
  FROM `ga4-product-analytics-511413.analytics.mart_sessions` AS s
  LEFT JOIN session_orders AS o USING (session_key)
  GROUP BY 1
)
SELECT country, observed_sessions, distinct_user_ids, purchasing_sessions, identifiable_orders,
  ROUND(identifiable_revenue_usd, 2) AS identifiable_revenue_usd,
  ROUND(100.0 * SAFE_DIVIDE(purchasing_sessions, observed_sessions), 2) AS purchase_presence_pct,
  ROUND(SAFE_DIVIDE(identifiable_revenue_usd, identifiable_orders), 2) AS identifiable_average_order_value_usd,
  ROUND(SAFE_DIVIDE(identifiable_revenue_usd, observed_sessions), 4) AS identifiable_revenue_per_session_usd
FROM country_metrics ORDER BY observed_sessions DESC LIMIT 15;
