-- Grain: one anonymous user identifier per event date.
-- No date partitioning: historical partitions may expire in Sandbox.
CREATE OR REPLACE TABLE
  `ga4-product-analytics-511413.analytics.mart_user_daily_activity`
CLUSTER BY user_pseudo_id
AS
SELECT
  user_pseudo_id,
  event_date AS activity_date,
  COUNT(*) AS event_count,
  COUNT(DISTINCT session_key) AS observed_session_count,
  COUNTIF(event_name = 'purchase') AS purchase_event_count
FROM `ga4-product-analytics-511413.analytics.stg_events`
GROUP BY user_pseudo_id, event_date;
