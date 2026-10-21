-- SIMULATED A/A: first-observed device balance.
-- Same eligibility and fixed hash assignment as the outcome analysis.
WITH user_entry AS (
  SELECT
    user_pseudo_id,
    MIN(event_date) AS cohort_date,
    ARRAY_AGG(
      STRUCT(device_category AS device_category)
      ORDER BY event_timestamp_micros, event_key
      LIMIT 1
    )[OFFSET(0)].device_category AS first_device
  FROM `ga4-product-analytics-511413.analytics.stg_events`
  GROUP BY user_pseudo_id
),
eligible_assigned AS (
  SELECT
    user_pseudo_id,
    COALESCE(NULLIF(TRIM(first_device), ''), 'unknown') AS first_device,
    CASE
      WHEN MOD(
        FARM_FINGERPRINT(CONCAT('simulated_aa_v1|', user_pseudo_id)), 2
      ) = 0 THEN 'A'
      ELSE 'B'
    END AS simulated_group
  FROM user_entry
  WHERE DATE_ADD(cohort_date, INTERVAL 6 DAY) <= (
    SELECT MAX(activity_date)
    FROM `ga4-product-analytics-511413.analytics.mart_user_daily_activity`
  )
)
SELECT
  simulated_group,
  first_device,
  COUNT(*) AS users,
  ROUND(
    100.0 * SAFE_DIVIDE(
      COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY simulated_group)
    ), 4
  ) AS within_group_pct
FROM eligible_assigned
GROUP BY simulated_group, first_device
ORDER BY first_device, simulated_group;
