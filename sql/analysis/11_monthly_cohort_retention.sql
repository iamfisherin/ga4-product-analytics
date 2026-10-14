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
  DATE_TRUNC(cohort_date, MONTH) AS cohort_month,
  retention_day,
  SUM(cohort_users) AS cohort_users,
  COUNT(*) AS observed_cohort_dates,
  COUNTIF(
    target_date <= observation_end_date
  ) AS mature_cohort_dates,
  CASE
    WHEN COUNTIF(target_date <= observation_end_date) = COUNT(*)
      THEN 'fully_mature'
    WHEN COUNTIF(target_date <= observation_end_date) = 0
      THEN 'immature'
    ELSE 'partially_mature'
  END AS maturity_status,
  SUM(
    IF(target_date <= observation_end_date, cohort_users, 0)
  ) AS eligible_users,
  SUM(
    IF(target_date <= observation_end_date, matched_users, NULL)
  ) AS retained_users,
  ROUND(
    100.0 * SAFE_DIVIDE(
      SUM(IF(target_date <= observation_end_date, matched_users, NULL)),
      SUM(IF(target_date <= observation_end_date, cohort_users, 0))
    ),
    4
  ) AS retention_pct
FROM cohort_counts
GROUP BY cohort_month, retention_day
ORDER BY cohort_month, retention_day;
