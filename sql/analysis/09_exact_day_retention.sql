-- Exact-day return retention, not rolling/cumulative retention.
-- Cohort date is first observed activity within the window.
-- It is NOT a registration date or verified new-customer date.
WITH observation_window AS (
  SELECT MAX(activity_date) AS observation_end_date
  FROM `ga4-product-analytics-511413.analytics.mart_user_daily_activity`
),
user_cohorts AS (
  SELECT
    user_pseudo_id,
    MIN(activity_date) AS cohort_date
  FROM `ga4-product-analytics-511413.analytics.mart_user_daily_activity`
  GROUP BY user_pseudo_id
),
retention_targets AS (
  SELECT
    u.user_pseudo_id,
    u.cohort_date,
    retention_day,
    DATE_ADD(u.cohort_date, INTERVAL retention_day DAY) AS target_date,
    w.observation_end_date
  FROM user_cohorts AS u
  CROSS JOIN UNNEST([1, 7, 14, 30]) AS retention_day
  CROSS JOIN observation_window AS w
),
cohort_counts AS (
  SELECT
    t.cohort_date,
    t.retention_day,
    t.target_date,
    t.observation_end_date,
    COUNT(*) AS cohort_users,
    COUNTIF(a.user_pseudo_id IS NOT NULL) AS matched_users
  FROM retention_targets AS t
  LEFT JOIN
    `ga4-product-analytics-511413.analytics.mart_user_daily_activity` AS a
    ON t.user_pseudo_id = a.user_pseudo_id
    AND t.target_date = a.activity_date
  GROUP BY
    t.cohort_date,
    t.retention_day,
    t.target_date,
    t.observation_end_date
)
SELECT
  retention_day,
  SUM(cohort_users) AS eligible_users,
  SUM(matched_users) AS retained_users,
  ROUND(
    100.0 * SAFE_DIVIDE(SUM(matched_users), SUM(cohort_users)),
    2
  ) AS retention_pct
FROM cohort_counts
WHERE target_date <= observation_end_date
GROUP BY retention_day
ORDER BY retention_day;
