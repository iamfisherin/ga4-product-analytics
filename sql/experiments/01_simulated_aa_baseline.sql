-- SIMULATED A/A ONLY: retrospective historical-data exercise.
-- No real treatment, exposure log, or causal product effect.
-- Outcome window: first-observed date through day 6 inclusive.
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
eligible_users AS (
  SELECT u.user_pseudo_id, u.cohort_date
  FROM user_cohorts AS u
  CROSS JOIN observation_window AS w
  WHERE DATE_ADD(u.cohort_date, INTERVAL 6 DAY) <= w.observation_end_date
),
user_outcomes AS (
  SELECT
    u.user_pseudo_id,
    u.cohort_date,
    SUM(a.purchase_event_count) AS purchase_events_7d,
    COUNTIF(a.purchase_event_count > 0) > 0 AS purchased_7d
  FROM eligible_users AS u
  LEFT JOIN
    `ga4-product-analytics-511413.analytics.mart_user_daily_activity` AS a
    ON u.user_pseudo_id = a.user_pseudo_id
    AND a.activity_date BETWEEN
      u.cohort_date AND DATE_ADD(u.cohort_date, INTERVAL 6 DAY)
  GROUP BY u.user_pseudo_id, u.cohort_date
)
SELECT
  COUNT(*) AS eligible_users,
  MIN(cohort_date) AS earliest_cohort_date,
  MAX(cohort_date) AS latest_cohort_date,
  COUNTIF(purchased_7d) AS purchasing_users_7d,
  SUM(purchase_events_7d) AS purchase_events_7d,
  ROUND(
    100.0 * SAFE_DIVIDE(COUNTIF(purchased_7d), COUNT(*)), 4
  ) AS user_purchase_rate_7d_pct
FROM user_outcomes;
