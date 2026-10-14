-- Expected:
-- 319066 rows, 270154 users, 92 days,
-- 4295584 events, 5692 purchase events,
-- 0 invalid rows, 0 duplicate user-date groups.
WITH duplicate_keys AS (
  SELECT user_pseudo_id, activity_date
  FROM `ga4-product-analytics-511413.analytics.mart_user_daily_activity`
  GROUP BY user_pseudo_id, activity_date
  HAVING COUNT(*) > 1
)
SELECT
  COUNT(*) AS user_day_rows,
  COUNT(DISTINCT user_pseudo_id) AS distinct_user_ids,
  COUNT(DISTINCT activity_date) AS observed_days,
  MIN(activity_date) AS first_activity_date,
  MAX(activity_date) AS last_activity_date,
  SUM(event_count) AS total_events,
  SUM(purchase_event_count) AS purchase_events,
  COUNTIF(
    user_pseudo_id IS NULL
    OR activity_date IS NULL
    OR activity_date < DATE '2020-11-01'
    OR activity_date > DATE '2021-01-31'
    OR event_count IS NULL
    OR event_count <= 0
    OR observed_session_count IS NULL
    OR observed_session_count <= 0
    OR observed_session_count > event_count
    OR purchase_event_count IS NULL
    OR purchase_event_count < 0
    OR purchase_event_count > event_count
  ) AS invalid_activity_rows,
  (SELECT COUNT(*) FROM duplicate_keys) AS duplicate_user_date_groups
FROM `ga4-product-analytics-511413.analytics.mart_user_daily_activity`;
